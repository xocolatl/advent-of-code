CREATE TABLE day03 (rownum serial, input text);

\COPY day03 (input) FROM 'input.txt'

/*
 * This doesn't really have anything to do with SQL, it's just some math.  I
 * use subqueries so I can name variables and make it a little bit clearer, but
 * it's just one formula.
 */
SELECT CASE WHEN input <= ne THEN sq_size/2 + abs(ne - sq_size/2 - input)
            WHEN input <= nw THEN sq_size/2 + abs(nw - sq_size/2 - input)
            WHEN input <= sw THEN sq_size/2 + abs(sw - sq_size/2 - input)
            WHEN input <= se THEN sq_size/2 + abs(se - sq_size/2 - input)
       END AS first_star
FROM (
    SELECT input,
           sq_size,
           sq_size*(sq_size-3)+3 AS ne,
           sq_size*(sq_size-2)+2 AS nw,
           sq_size*(sq_size-1)+1 AS sw,
           sq_size*sq_size AS se
    FROM (
        SELECT input,
               sq + 1 - (sq % 2) AS sq_size
        FROM (
            SELECT d.input::integer,
                   ceil(sqrt(input::integer))::integer AS sq
            FROM day03 AS d
        ) _
    ) _
) _;

/*
 * I really, really wanted to do this in a single query with a recursive CTE,
 * but...
 *
 * ERROR: aggregate functions are not allowed in a recursive query's recursive term
 * ERROR: recursive reference to query "grid" must not appear within a subquery
 * ERROR: recursive reference to query "grid" must not appear within an outer join
 *
 * I don't know if PostgreSQL can be improved to allow these cases or not.
 * Once I decided I needed to use a function, I decided to go whole hog and
 * create two.
 */

CREATE OR REPLACE FUNCTION get_coords(number integer, OUT x integer, OUT y integer)
 RETURNS record
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
SELECT CASE WHEN input <= ne THEN sq_size
            WHEN input <= nw THEN nw-input+1
            WHEN input <= sw THEN 1
            WHEN input <= se THEN input-se+sq_size
       END - sq_size/2 - 1 AS x,
       CASE WHEN input < ne THEN input-ne+sq_size
            WHEN input <= nw THEN sq_size
            WHEN input < sw THEN sw-input+1
            WHEN input <= se THEN 1
       END - sq_size/2 - 1 AS y
FROM (
    SELECT input,
           sq_size,
           sq_size*(sq_size-3)+3 AS ne,
           sq_size*(sq_size-2)+2 AS nw,
           sq_size*(sq_size-1)+1 AS sw,
           sq_size*sq_size AS se
    FROM (
        SELECT input,
               sq + 1 - (sq % 2) AS sq_size
        FROM (
            SELECT $1 AS input,
                   ceil(sqrt($1))::integer AS sq
        ) _
    ) _
) _
$function$;

CREATE OR REPLACE FUNCTION second_star(input integer)
 RETURNS integer
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
    l_number integer default 1;
    l_result integer default 0;
BEGIN
    CREATE TEMPORARY TABLE grid (
        number integer,
        x integer,
        y integer,
        value integer)
    ON COMMIT DROP;

    INSERT INTO grid VALUES (1, 0, 0, 1);

    WHILE l_result <= input LOOP
        l_number := l_number + 1;

        INSERT INTO grid
            SELECT l_number, c.x, c.y, sum(g.value)
            FROM get_coords(l_number) AS c,
                 grid AS g
            WHERE g.x BETWEEN c.x-1 AND c.x+1
              AND g.y BETWEEN c.y-1 AND c.y+1
            GROUP BY l_number, c.x, c.y
        RETURNING value
        INTO l_result;
    END LOOP;

    RETURN l_result;
END;
$function$;

SELECT second_star(input::integer)
FROM day03;

DROP FUNCTION second_star(integer);
DROP FUNCTION get_coords(integer);
DROP TABLE day03;
