CREATE SCHEMA IF NOT EXISTS aoc2022;
SET SCHEMA 'aoc2022';
DROP TABLE IF EXISTS dec25;

CREATE TABLE dec25 (
    line_number INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    line CHARACTER VARYING
);

\COPY dec25 (line) FROM '2022/dec25.input'
VACUUM ANALYZE dec25;

/* FIRST STAR */

WITH RECURSIVE

input (line_number, value) AS (
    SELECT d.line_number, SUM(v.digit * v.units)
    FROM dec25 AS d
    CROSS JOIN LATERAL string_to_table(reverse(d.line), NULL) WITH ORDINALITY AS s (digit, position)
    CROSS JOIN LATERAL (VALUES (
        CASE s.digit
        WHEN '-' THEN -1
        WHEN '=' THEN -2
        ELSE CAST(s.digit AS INTEGER)
        END,

        POWER(5, s.position-1)
    )) AS v (digit, units)
    GROUP BY d.line_number
),

to_snafu (value, result) AS (
    SELECT CAST(SUM(value) AS BIGINT), ''
    FROM input

    UNION ALL

    SELECT (ts.value + CASE WHEN ts.value > 2 THEN 2 ELSE 0 END) / 5,
           ts.result || SUBSTRING('012=-' FROM CAST(MOD(ts.value, 5) AS INTEGER) + 1 FOR 1)
    FROM to_snafu AS ts
    WHERE ts.value > 0
)

SELECT reverse(result)
FROM to_snafu
WHERE value = 0
;
