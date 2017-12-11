CREATE TABLE day11 (rownum serial, input text);

\COPY day11 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT u.dir, u.ord
    FROM day11 AS d,
         unnest(string_to_array(d.input, ',')) WITH ORDINALITY u(dir, ord)
),
loop (x, y, z, step, dist) AS (
    SELECT 0, 0, 0, 0, 0
    UNION ALL
    (WITH calc (x, y, z, step) AS (
        SELECT CASE WHEN i.dir IN ('ne', 'se') THEN l.x+1
                    WHEN i.dir IN ('nw', 'sw') THEN l.x-1
                    ELSE l.x
               END,
               CASE WHEN i.dir IN ( 'n', 'nw') THEN l.y+1
                    WHEN i.dir IN ( 's', 'se') THEN l.y-1
                    ELSE l.y
               END,
               CASE WHEN i.dir IN ( 's', 'sw') THEN l.z+1
                    WHEN i.dir IN ( 'n', 'ne') THEN l.z-1
                    ELSE l.z
               END,
               l.step+1
        FROM loop AS l
        JOIN input AS i ON i.ord = l.step+1
    )
    SELECT calc.x,
           calc.y,
           calc.z,
           calc.step,
           (abs(calc.x) + abs(calc.y) + abs(calc.z)) / 2
    FROM calc)
)
SELECT first_value(dist) OVER (ORDER BY step DESC) AS first_star,
       max(dist) OVER () AS second_star
FROM loop
ORDER BY step DESC
LIMIT 1;

DROP TABLE day11;
