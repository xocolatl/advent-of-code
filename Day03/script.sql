CREATE TABLE day03 (input text);

\COPY day03 FROM 'input.txt';

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

DROP TABLE day03;
