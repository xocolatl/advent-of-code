CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec03;

CREATE TABLE dec03 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec03 (line) FROM '2024/dec03.input' NULL ''
VACUUM ANALYZE dec03;

/**************/
/* FIRST STAR */
/**************/

SELECT SUM(CAST(m[1] AS BIGINT) * CAST(m[2] AS BIGINT)) AS first_star
FROM dec03
CROSS JOIN LATERAL regexp_matches(line, 'mul\((\d{1,3}),(\d{1,3})\)', 'g') AS m
;

/***************/
/* SECOND STAR */
/***************/

/*
 * This whole query can be greatly simplified whenever PostgreSQL implements
 * LAG() IGNORE NULLS
 */

WITH

input (command, product, grp) AS (
    SELECT a.command,
           a.product,
           COUNT(a.command) OVER (ORDER BY dec03.line_number, m.ordinality)
    FROM dec03
    CROSS JOIN LATERAL regexp_matches(line, '((mul)\((\d{1,3}),(\d{1,3})\)|(do)\(\)|(don''t)\(\))', 'g') WITH ORDINALITY AS m (match, ordinality)
    CROSS JOIN LATERAL (VALUES (
        COALESCE(m.match[5], m.match[6]),
        CAST(m.match[3] AS BIGINT) * CAST(m.match[4] AS BIGINT))
    ) AS a (command, product)
),

fill (product, enabled) AS (
    SELECT product,
           FIRST_VALUE(command) OVER (PARTITION BY grp) IS DISTINCT FROM 'don''t'
    FROM input
)

SELECT SUM(product) AS second_star
FROM fill
WHERE enabled
;
