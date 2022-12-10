CREATE SCHEMA IF NOT EXISTS aoc2022;
SET SCHEMA 'aoc2022';
DROP TABLE IF EXISTS dec10;

CREATE TABLE dec10 (
    line_number INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    line CHARACTER VARYING
);

\COPY dec10 (line) FROM '2022/dec10.input'
VACUUM ANALYZE dec10;

/* FIRST STAR */

WITH

cycles (cycle, v) AS (
    SELECT ROW_NUMBER() OVER (ORDER BY d.line_number, s.ord),
           CASE WHEN s.ord = 2 THEN CAST(s.v AS INTEGER) END
    FROM dec10 AS d
    CROSS JOIN LATERAL string_to_table(d.line, ' ') WITH ORDINALITY AS s (v, ord)
),

calc (cycle, x) AS (
    SELECT cycle,
           SUM(v) OVER (ORDER BY cycle ROWS UNBOUNDED PRECEDING EXCLUDE CURRENT ROW) + 1
    FROM cycles
)

SELECT SUM(cycle * x) AS first_star
FROM calc
WHERE cycle IN (20, 60, 100, 140, 180, 220)
;

/* SECOND STAR */

WITH

cycles (cycle, v) AS (
    SELECT ROW_NUMBER() OVER (ORDER BY d.line_number, s.ord),
           CASE WHEN s.ord = 2 THEN CAST(s.v AS INTEGER) END
    FROM dec10 AS d
    CROSS JOIN LATERAL string_to_table(d.line, ' ') WITH ORDINALITY AS s (v, ord)
),

calc (cycle, x) AS (
    SELECT cycle,
           COALESCE(SUM(v) OVER w + 1, 1)
    FROM cycles
    WINDOW w AS (ORDER BY cycle ROWS UNBOUNDED PRECEDING EXCLUDE CURRENT ROW)
),

ray (cycle, pixel, line) AS (
    SELECT cycle,
           CASE WHEN MOD(cycle-1, 40) BETWEEN x-1 AND x+1 THEN U&'\2588' ELSE ' ' END,
           (cycle - 1) / 40
    FROM calc
)

SELECT string_agg(pixel, '' ORDER BY cycle) AS second_star
FROM ray
GROUP BY line
ORDER BY line
;
