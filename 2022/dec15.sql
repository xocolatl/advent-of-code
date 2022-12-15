CREATE SCHEMA IF NOT EXISTS aoc2022;
SET SCHEMA 'aoc2022';
DROP TABLE IF EXISTS dec15;

CREATE TABLE dec15 (
    line_number INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    line CHARACTER VARYING
);

\COPY dec15 (line) FROM '2022/dec15.input'
VACUUM ANALYZE dec15;

/* FIRST STAR */

WITH

input (sx, sy, cbx, cby, manhattan) AS materialized (
    SELECT sx, sy, cbx, cby,
           ABS(sx-cbx) + ABS(sy-cby)
    FROM dec15 AS d
    CROSS JOIN LATERAL regexp_matches(d.line, 'Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)') AS m
    CROSS JOIN LATERAL (VALUES (
        CAST(m[1] AS BIGINT),
        CAST(m[2] AS BIGINT),
        CAST(m[3] AS BIGINT),
        CAST(m[4] AS BIGINT)
    )) AS v (sx, sy, cbx, cby)
),

ranges (ranges) AS (
    SELECT range_agg(int8multirange(int8range(sx - (manhattan - ABS(sy - 2000000)), sx + (manhattan - ABS(sy - 2000000)), '[]')))
    FROM input AS i
    WHERE manhattan >= ABS(sy - 2000000)
)

SELECT SUM(upper(range) - lower(range)) - (SELECT COUNT(DISTINCT (cbx, cby)) FROM input WHERE cby = 2000000) AS first_star
FROM ranges AS r
CROSS JOIN LATERAL unnest(r.ranges) AS u (range)
;

/* SECOND STAR */

WITH

input (sx, sy, cbx, cby, manhattan) AS materialized (
    SELECT sx, sy, cbx, cby,
           ABS(sx-cbx) + ABS(sy-cby)
    FROM dec15 AS d
    CROSS JOIN LATERAL regexp_matches(d.line, 'Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)') AS m
    CROSS JOIN LATERAL (VALUES (
        CAST(m[1] AS BIGINT),
        CAST(m[2] AS BIGINT),
        CAST(m[3] AS BIGINT),
        CAST(m[4] AS BIGINT)
    )) AS v (sx, sy, cbx, cby)
),

ranges (y, ranges) AS (
    SELECT y, range_agg(int8multirange(int8range(sx - (manhattan - ABS(sy - y)), sx + (manhattan - ABS(sy - y)), '[]')))
    FROM input AS i
    CROSS JOIN generate_series(0, 4000000) AS y
    WHERE manhattan >= ABS(sy - y)
    GROUP BY y
)

SELECT 4000000 * lower(int8multirange(range_merge(r.ranges)) - r.ranges) + r.y AS second_star
FROM ranges AS r
WHERE (SELECT COUNT(*) FROM UNNEST(r.ranges)) > 1 -- multiranges don't have a length() function (yet!)
FETCH FIRST ROW ONLY
;
