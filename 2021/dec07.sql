CREATE SCHEMA IF NOT EXISTS aoc2021;
SET SCHEMA 'aoc2021';
DROP TABLE IF EXISTS dec07;

CREATE TABLE dec07 (
    line_number bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    value text NOT NULL
);

\COPY dec07 (value) FROM '2021/dec07.input'
VACUUM ANALYZE dec07;

/* FIRST STAR */

/*
 * The ideal meeting position is the median of all the positions.  In SQL, the
 * median is expressed as PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pos).
 *
 * The query is then just summing up the fuel used to get to that median position.
 */

WITH

input (pos, ord) AS (
    SELECT CAST(pos AS bigint), ord
    FROM dec07
    CROSS JOIN LATERAL string_to_table(value, ',') WITH ORDINALITY AS s (pos, ord)
),

target (pos) AS (
    SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY pos)
    FROM input
)

SELECT sum(abs(pos - (TABLE target))) AS first_star
FROM input
;

/* SECOND STAR */

/*
 * My math skills aren't good enough to calculate the meet point so just
 * calculate ALL the meet points and pick the one that uses the least fuel.
 * Not pretty, but it works.
 */

WITH

input (pos, ord) AS (
    SELECT CAST(pos AS bigint), ord
    FROM dec07
    CROSS JOIN LATERAL string_to_table(value, ',') WITH ORDINALITY AS s (pos, ord)
),

targets (pos) AS (
    SELECT *
    FROM generate_series(
        (SELECT min(pos) FROM input),
        (SELECT max(pos) FROM input))
)

SELECT sum(distance * (distance + 1) / 2) AS second_star
FROM input AS i
CROSS JOIN targets AS t
CROSS JOIN LATERAL (VALUES (abs(i.pos - t.pos))) AS v (distance)
GROUP BY t.pos
ORDER BY second_star
FETCH FIRST ROW ONLY
;

