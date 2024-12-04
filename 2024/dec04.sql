CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec04;

CREATE TABLE dec04 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec04 (line) FROM '2024/dec04.input' NULL ''
VACUUM ANALYZE dec04;

/**************/
/* FIRST STAR */
/**************/

WITH

input (x, y, letter) AS (
    SELECT s.ordinality, d.line_number, s.letter
    FROM dec04 AS d
    CROSS JOIN LATERAL string_to_table(d.line, NULL) WITH ORDINALITY AS s (letter, ordinality)
),

words AS (
    SELECT x, y, letter,
           string_agg(letter, NULL) OVER ltr AS ltr,
           string_agg(letter, NULL) OVER rtl AS rtl,
           string_agg(letter, NULL) OVER ttb AS ttb,
           string_agg(letter, NULL) OVER btt AS btt,
           string_agg(letter, NULL) OVER pd1 AS pd1,
           string_agg(letter, NULL) OVER pd2 AS pd2,
           string_agg(letter, NULL) OVER nd1 AS nd1,
           string_agg(letter, NULL) OVER nd2 AS nd2
    FROM input
    WINDOW
        ltr AS (PARTITION BY y ORDER BY  x ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING),
        rtl AS (PARTITION BY y ORDER BY -x ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING),
        ttb AS (PARTITION BY x ORDER BY  y ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING),
        btt AS (PARTITION BY x ORDER BY -y ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING),
        pd1 AS (PARTITION BY x+y ORDER BY  x ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING),
        pd2 AS (PARTITION BY x+y ORDER BY -x ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING),
        nd1 AS (PARTITION BY x-y ORDER BY  x ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING),
        nd2 AS (PARTITION BY x-y ORDER BY -x ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING)
)

SELECT   COUNT(*) FILTER (WHERE ltr = 'XMAS')
       + COUNT(*) FILTER (WHERE rtl = 'XMAS')
       + COUNT(*) FILTER (WHERE ttb = 'XMAS')
       + COUNT(*) FILTER (WHERE btt = 'XMAS')
       + COUNT(*) FILTER (WHERE pd1 = 'XMAS')
       + COUNT(*) FILTER (WHERE pd2 = 'XMAS')
       + COUNT(*) FILTER (WHERE nd1 = 'XMAS')
       + COUNT(*) FILTER (WHERE nd2 = 'XMAS') AS first_star
FROM words
;

/***************/
/* SECOND STAR */
/***************/
 
WITH

input (x, y, letter) AS (
    SELECT s.ordinality, d.line_number, s.letter
    FROM dec04 AS d
    CROSS JOIN LATERAL string_to_table(d.line, NULL) WITH ORDINALITY AS s (letter, ordinality)
),

words AS (
    SELECT x, y, letter,
           string_agg(letter, NULL) OVER pd1 AS pd1,
           string_agg(letter, NULL) OVER pd2 AS pd2,
           string_agg(letter, NULL) OVER nd1 AS nd1,
           string_agg(letter, NULL) OVER nd2 AS nd2
    FROM input
    WINDOW
        pd1 AS (PARTITION BY y+x ORDER BY  x ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
        pd2 AS (PARTITION BY y+x ORDER BY -x ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
        nd1 AS (PARTITION BY x-y ORDER BY  x ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING),
        nd2 AS (PARTITION BY x-y ORDER BY -x ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
)

SELECT COUNT(*) AS second_star
FROM words
WHERE num_nonnulls(CASE WHEN pd1 = 'MAS' THEN pd1 END,
                   CASE WHEN pd2 = 'MAS' THEN pd2 END,
                   CASE WHEN nd1 = 'MAS' THEN nd1 END,
                   CASE WHEN nd2 = 'MAS' THEN nd2 END) = 2
;

