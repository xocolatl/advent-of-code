CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec02;

CREATE TABLE dec02 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec02 (line) FROM '2024/dec02.input' NULL ''
VACUUM ANALYZE dec02;

/**************/
/* FIRST STAR */
/**************/

WITH

reports (report, level, ordinality) AS (
    SELECT line_number, CAST(level AS INTEGER), ordinality
    FROM dec02
    CROSS JOIN LATERAL string_to_table(line, ' ') WITH ORDINALITY AS reports (level, ordinality)
),

deltas (report, delta) AS (
    SELECT report, level - LAG(level) OVER w
    FROM reports
    WINDOW w AS (PARTITION BY report ORDER BY ordinality)
),

safe_reports (safe_report) AS (
    SELECT report
    FROM deltas
    GROUP BY report
    HAVING EVERY(delta BETWEEN 1 AND 3) OR EVERY(delta BETWEEN -3 AND -1)
)

SELECT COUNT(*) AS first_star
FROM safe_reports
;

/***************/
/* SECOND STAR */
/***************/

WITH

reports (report, levels) AS (
    SELECT line_number, CAST(levels AS INTEGER ARRAY)
    FROM dec02
    CROSS JOIN LATERAL string_to_array(line, ' ') AS reports (levels)
),

deltas (report, removed, delta) AS (
    SELECT report, removed, level - LAG(level) OVER w AS delta
    FROM reports
    CROSS JOIN LATERAL generate_series(0, CARDINALITY(levels)) AS g (removed)
    CROSS JOIN LATERAL UNNEST(levels) WITH ORDINALITY AS u (level, ordinality)
    WHERE ordinality <> removed
    WINDOW w AS (PARTITION BY report, removed ORDER BY ordinality)
),

safe_reports (report) AS (
    SELECT DISTINCT report
    FROM deltas
    GROUP BY report, removed
    HAVING EVERY(delta BETWEEN 1 AND 3) OR EVERY(delta BETWEEN -3 AND -1)
)

SELECT COUNT(*) AS second_star
FROM safe_reports
;
