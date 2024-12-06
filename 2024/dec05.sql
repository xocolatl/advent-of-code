CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec05;

CREATE TABLE dec05 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec05 (line) FROM '2024/dec05.input' NULL ''
VACUUM ANALYZE dec05;

/**************/
/* FIRST STAR */
/**************/

WITH

ordering_rules (before, after) AS (
    SELECT CAST(m[1] AS INTEGER), CAST(m[2] AS INTEGER)
    FROM dec05
    CROSS JOIN LATERAL regexp_match(line, '^(\d+)\|(\d+)$') AS m
    WHERE POSITION('|' IN line) > 0
),

updates (line_number, pages) AS (
    SELECT line_number, CAST(sta AS INTEGER ARRAY)
    FROM dec05
    CROSS JOIN LATERAL string_to_array(line, ',') AS sta
    WHERE POSITION(',' IN line) > 0
),

filtered (line_number, pages) AS (
    SELECT u.line_number, u.pages
    FROM updates AS u
    JOIN ordering_rules AS o ON ARRAY[o.before, o.after] <@ u.pages
    GROUP BY u.line_number, u.pages
    HAVING EVERY(array_position(u.pages, o.before) < array_position(u.pages, o.after))
)

SELECT SUM(pages[CARDINALITY(pages)/2+1]) AS first_star
FROM filtered
;

/***************/
/* SECOND STAR */
/***************/
 
WITH RECURSIVE

ordering_rules (before, after) AS (
    SELECT CAST(m[1] AS INTEGER), CAST(m[2] AS INTEGER)
    FROM dec05
    CROSS JOIN LATERAL regexp_match(line, '^(\d+)\|(\d+)$') AS m
    WHERE POSITION('|' IN line) > 0
),

updates (line_number, pages) AS (
    SELECT line_number, CAST(sta AS INTEGER ARRAY)
    FROM dec05
    CROSS JOIN LATERAL string_to_array(line, ',') AS sta
    WHERE POSITION(',' IN line) > 0
),

filtered (line_number, pages) AS (
    SELECT line_number, pages
    FROM updates AS u
    JOIN ordering_rules AS o ON ARRAY[o.before, o.after] <@ u.pages
    GROUP BY line_number, pages
    HAVING NOT EVERY(array_position(u.pages, o.before) < array_position(u.pages, o.after))
),

sort (pages, after, sorted) AS (
    SELECT f.pages, o.after, ARRAY[o.before, o.after]
    FROM filtered AS f
    JOIN ordering_rules AS o ON ARRAY[o.before, o.after] <@ f.pages

    UNION ALL

    SELECT s.pages, o.after, s.sorted || o.after
    FROM sort AS s
    JOIN ordering_rules AS o ON o.before = s.after AND o.after = ANY (s.pages)
)

SELECT SUM(sorted[CARDINALITY(sorted)/2+1]) AS second_star
FROM sort
WHERE CARDINALITY(pages) = CARDINALITY(sorted)
;
