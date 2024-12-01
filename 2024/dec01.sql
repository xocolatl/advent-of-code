CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec01;

CREATE TABLE dec01 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec01 (line) FROM '2024/dec01.input' NULL ''
VACUUM ANALYZE dec01;

/**************/
/* FIRST STAR */
/**************/

WITH

sorted_locations (location_a, location_b) AS (
    SELECT ARRAY_AGG(la ORDER BY la),
           ARRAY_AGG(lb ORDER BY lb)
    FROM dec01
    CROSS JOIN LATERAL regexp_match(line, '(\d+)\s+(\d+)') AS m
    CROSS JOIN LATERAL (VALUES (CAST(m[1] AS BIGINT), CAST(m[2] AS BIGINT))) AS v (la, lb)
)

SELECT SUM(ABS(u.a - u.b)) AS first_star
FROM sorted_locations AS sl
CROSS JOIN LATERAL UNNEST(sl.location_a, sl.location_b) AS u(a, b)
;

/***************/
/* SECOND STAR */
/***************/

WITH

locations (line_number, location_a, location_b) AS (
    SELECT line_number, la, lb
    FROM dec01
    CROSS JOIN LATERAL regexp_match(line, '(\d+)\s+(\d+)') AS m
    CROSS JOIN LATERAL (VALUES (CAST(m[1] AS BIGINT), CAST(m[2] AS BIGINT))) AS v (la, lb)
),

location_counts(location, count) AS (
    SELECT loc1.location_a, COUNT(*)
    FROM locations AS loc1
    JOIN locations AS loc2 ON loc2.location_b = loc1.location_a
    GROUP BY loc1.line_number, loc1.location_a
)

SELECT SUM(location * count) AS second_star
FROM location_counts
;

