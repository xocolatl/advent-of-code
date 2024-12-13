CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec13;

CREATE TABLE dec13 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec13 (line) FROM '2024/dec13.input' NULL ''
VACUUM ANALYZE dec13;

/**************/
/* FIRST STAR */
/**************/

WITH

input (a_x, a_y, b_x, b_y, prize_x, prize_y) AS (
    SELECT CAST(m[1] AS INTEGER),
           CAST(m[2] AS INTEGER),
           CAST(m[3] AS INTEGER),
           CAST(m[4] AS INTEGER),
           CAST(m[5] AS INTEGER),
           CAST(m[6] AS INTEGER)
    FROM (
        SELECT line_number, string_agg(line, ' ') OVER w AS specs
        FROM dec13
        WINDOW w AS (ORDER BY line_number ROWS 2 PRECEDING)
    )
    CROSS JOIN LATERAL regexp_match(specs, '^Button A: X\+(\d+), Y\+(\d+) Button B: X\+(\d+), Y\+(\d+) Prize: X=(\d+), Y=(\d+)$') AS m
    WHERE MOD(line_number, 4) = 3
)

SELECT SUM(3*CAST(m AS INTEGER) + CAST(n AS INTEGER)) AS first_star
FROM (
    SELECT 1.0 * (prize_x * b_y - prize_y * b_x) / (a_x * b_y - a_y * b_x) AS m,
           1.0 * (a_x * prize_y - a_y * prize_x) / (a_x * b_y - a_y * b_x) AS n
    FROM input
)
WHERE m - trunc(m) = 0
  AND n - trunc(n) = 0
;

/***************/
/* SECOND STAR */
/***************/
 
WITH

input (a_x, a_y, b_x, b_y, prize_x, prize_y) AS (
    SELECT CAST(m[1] AS BIGINT),
           CAST(m[2] AS BIGINT),
           CAST(m[3] AS BIGINT),
           CAST(m[4] AS BIGINT),
           CAST(m[5] AS BIGINT) + 10000000000000,
           CAST(m[6] AS BIGINT) + 10000000000000
    FROM (
        SELECT line_number, string_agg(line, ' ') OVER w AS specs
        FROM dec13
        WINDOW w AS (ORDER BY line_number ROWS 2 PRECEDING)
    )
    CROSS JOIN LATERAL regexp_match(specs, '^Button A: X\+(\d+), Y\+(\d+) Button B: X\+(\d+), Y\+(\d+) Prize: X=(\d+), Y=(\d+)$') AS m
    WHERE MOD(line_number, 4) = 3
)

SELECT SUM(3*CAST(m AS BIGINT) + CAST(n AS BIGINT)) AS second_star
FROM (
    SELECT 1.0 * (prize_x * b_y - prize_y * b_x) / (a_x * b_y - a_y * b_x) AS m,
           1.0 * (a_x * prize_y - a_y * prize_x) / (a_x * b_y - a_y * b_x) AS n
    FROM input
)
WHERE m - trunc(m) = 0
  AND n - trunc(n) = 0
;
