DROP TABLE IF EXISTS dec03;
CREATE TABLE dec03 (
    wire integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    directions text NOT NULL
);

\COPY dec03 (directions) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/3/input';

-- This one is easier if we combine both stars into the same query as only the
-- main part of the query differs.  It may be possible to factorize them even
-- more.

WITH RECURSIVE

tracer (wire, directions, path, x, y) AS (
    SELECT wire,
           regexp_split_to_array(directions, ','),
           CAST(ARRAY[] AS record[]),
           0, 0
    FROM dec03

    UNION ALL

    SELECT wire,
           directions[2:],

           /* path */
           CASE dir
           WHEN 'L' THEN path || ARRAY(SELECT ROW(g, y) FROM generate_series(x-1, x-step, -1) AS g)
           WHEN 'R' THEN path || ARRAY(SELECT ROW(g, y) FROM generate_series(x+1, x+step) AS g)
           WHEN 'U' THEN path || ARRAY(SELECT ROW(x, g) FROM generate_series(y+1, y+step) AS g)
           WHEN 'D' THEN path || ARRAY(SELECT ROW(x, g) FROM generate_series(y-1, y-step, -1) AS g)
           ELSE path
           END,

           /* x */
           CASE dir
           WHEN 'L' THEN x - step
           WHEN 'R' THEN x + step
           ELSE x
           END,

           /* y */
           CASE dir
           WHEN 'U' THEN y + step
           WHEN 'D' THEN y - step
           ELSE y
           END
    FROM tracer
    CROSS JOIN LATERAL (
        VALUES (substring(directions[1] FOR 1),
                CAST(substring(directions[1] FROM 2) AS integer))
    ) AS v(dir, step)
    WHERE directions <> '{}'
),

first_star (first_star) AS (
    SELECT abs(u.x) + abs(u.y) AS first_star
    FROM tracer
    CROSS JOIN ROWS FROM (unnest(path) AS (x integer, y integer)) AS u
    WHERE directions = '{}'
    GROUP BY u.x, u.y
    HAVING array_agg(wire) @> ARRAY[1, 2]
    ORDER BY first_star
    FETCH FIRST ROW ONLY
),

second_star (second_star) AS (
    SELECT sum(u.ordinality) AS second_star
    FROM tracer
    CROSS JOIN ROWS FROM (unnest(path) AS (x integer, y integer)) WITH ORDINALITY AS u
    WHERE directions = '{}'
    GROUP BY u.x, u.y
    HAVING array_agg(wire) @> ARRAY[1, 2]
    ORDER BY second_star
    FETCH FIRST ROW ONLY
)

SELECT first_star, second_star
FROM first_star
CROSS JOIN second_star;
