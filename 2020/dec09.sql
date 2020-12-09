DROP TABLE IF EXISTS dec09;
CREATE TABLE dec09 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    number bigint NOT NULL
);

\COPY dec09 (number) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/9/input';
VACUUM ANALYZE dec09;

\timing on

/* FIRST STAR */

WITH

input (ord, sum, candidates) AS (
    SELECT line_number,
           number,
           array_agg(number) OVER w
    FROM dec09
    WINDOW w AS (ORDER BY line_number ROWS BETWEEN 25 PRECEDING AND 1 PRECEDING)
    ORDER BY line_number
    OFFSET 25
)

SELECT sum AS first_star
FROM input
WHERE NOT EXISTS (
    SELECT
    FROM unnest(candidates) AS a,
         unnest(candidates) AS b
    WHERE a + b = sum
)
\gset

VALUES(:first_star);

/* SECOND STAR */

WITH RECURSIVE

search (line_number, min_number, max_number, sum) AS (
    SELECT line_number, number, number, number
    FROM dec09

    UNION ALL

    SELECT d.line_number,
           LEAST(s.min_number, d.number),
           GREATEST(s.max_number, d.number),
           s.sum + d.number
    FROM search AS s
    JOIN dec09 AS d ON d.line_number = s.line_number + 1
    WHERE s.sum + d.number <= :first_star
)

SELECT min_number + max_number
FROM search
WHERE sum = :first_star
  AND min_number <> max_number
;
