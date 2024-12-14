CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec14;

CREATE TABLE dec14 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec14 (line) FROM '2024/dec14.input' NULL ''
VACUUM ANALYZE dec14;

/**************/
/* FIRST STAR */
/**************/

WITH

input (x, y, dx, dy) AS (
    SELECT CAST(m[1] AS INTEGER),
           CAST(m[2] AS INTEGER),
           CAST(m[3] AS INTEGER),
           CAST(m[4] AS INTEGER)
    FROM dec14
    CROSS JOIN LATERAL regexp_match(line, 'p=(\d+),(\d+) v=(-?\d+),(-?\d+)') AS m
)

SELECT COUNT(*) FILTER (WHERE new_x < width/2 AND new_y < height/2) *
       COUNT(*) FILTER (WHERE new_x < width/2 AND new_y > height/2) *
       COUNT(*) FILTER (WHERE new_x > width/2 AND new_y < height/2) *
       COUNT(*) FILTER (WHERE new_x > width/2 AND new_y > height/2) AS first_star
FROM input
CROSS JOIN (VALUES (101, 103, 100)) AS consts (width, height, steps)
CROSS JOIN LATERAL (VALUES (MOD(x + steps*(dx+width), width), MOD(y + steps*(dy+height), height))) AS v (new_x, new_y)
;

/***************/
/* SECOND STAR */
/***************/
 
WITH

input (x, y, dx, dy) AS (
    SELECT CAST(m[1] AS INTEGER),
           CAST(m[2] AS INTEGER),
           CAST(m[3] AS INTEGER),
           CAST(m[4] AS INTEGER)
    FROM dec14
    CROSS JOIN LATERAL regexp_match(line, 'p=(\d+),(\d+) v=(-?\d+),(-?\d+)') AS m
)

SELECT steps AS second_star
FROM input AS i
CROSS JOIN (VALUES (101, 103)) AS consts (width, height)
CROSS JOIN LATERAL generate_series(0, width*height) AS g (steps)
CROSS JOIN LATERAL (VALUES (MOD(x + steps*(dx+width), width), MOD(y + steps*(dy+height), height))) AS v (new_x, new_y)
GROUP BY steps
HAVING COUNT(*) = COUNT(DISTINCT (new_x, new_y))
ORDER BY steps
FETCH FIRST ROW ONLY
;
