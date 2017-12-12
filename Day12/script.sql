CREATE TABLE day12 (rownum serial, input text);

\COPY day12 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT match[1]::integer AS id,
           string_to_array(match[2], ', ')::integer[] AS pipes
    FROM day12,
         regexp_match(input, '^(\d+) <-> (.*)$') AS match
),
loop AS (
    SELECT id, pipes, ARRAY[id] AS seen
    FROM input
    WHERE id = 0
    UNION ALL
    SELECT i.id, i.pipes, l.seen || i.id
    FROM input AS i
    JOIN loop AS l ON i.id = ANY (l.pipes)
    WHERE i.id <> ALL (l.seen)
)
SELECT count(*) AS first_star
FROM loop;

/* Will have to think more about how this can be made into a plain query */

CREATE OR REPLACE FUNCTION second_star()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    l_pipe_group integer;
BEGIN
    CREATE TEMPORARY TABLE input (
        id integer,
        pipes integer[],
        pipe_group integer
    ) ON COMMIT DROP;

    INSERT INTO input
        SELECT match[1]::integer,
               string_to_array(match[2], ', ')::integer[],
               null
        FROM day12,
             regexp_match(input, '^(\d+) <-> (.*)$') AS match;

    LOOP
        SELECT min(id)
        FROM input
        WHERE pipe_group IS NULL
        INTO l_pipe_group;

        EXIT WHEN l_pipe_group IS NULL;

        WITH RECURSIVE
        loop AS (
            SELECT id, pipes, ARRAY[id] AS seen
            FROM input
            WHERE id = l_pipe_group
            UNION ALL
            SELECT i.id, i.pipes, l.seen || i.id
            FROM input AS i
            JOIN loop AS l ON i.id = ANY (l.pipes)
            WHERE i.id <> ALL (l.seen)
        )
        UPDATE input SET
            pipe_group = l_pipe_group
        FROM loop
        WHERE input.id = loop.id;
    END LOOP;

    RETURN (SELECT count(DISTINCT pipe_group) FROM input);
END;
$function$;

SELECT second_star();

DROP FUNCTION second_star();
DROP TABLE day12;
