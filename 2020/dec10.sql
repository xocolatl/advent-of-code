DROP TABLE IF EXISTS dec10;
CREATE TABLE dec10 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    jolts integer NOT NULL
);

\COPY dec10 (jolts) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/10/input';
VACUUM ANALYZE dec10;

\timing on

/* FIRST STAR */

SELECT count(*) FILTER (WHERE diff = 1) * (1 + count(*) FILTER (WHERE diff = 3))
FROM (
    SELECT jolts - lag(jolts::integer, 1, 0) OVER (ORDER BY jolts) AS diff
    FROM dec10
) AS _
;

/* SECOND STAR */

WITH RECURSIVE

slide (jolts, combos, depth) AS (
    VALUES (ARRAY[0], ARRAY[1::numeric], 0)

    UNION ALL

    SELECT d.jolts || s.jolts,
           u.combos || s.combos,
           s.depth+1
    FROM slide AS s,
         LATERAL (
            SELECT d.jolts
            FROM d10 AS d
            WHERE d.jolts > s.jolts[1]
            ORDER BY d.jolts
            FETCH FIRST ROW ONLY
         ) AS d,
         LATERAL (
            SELECT d.jolts, sum(u.combo)
            FROM unnest(s.jolts, s.combos) AS u (jolt, combo)
            WHERE u.jolt >= d.jolts - 3
         ) AS u (jolts, combos)
)

SELECT combos[1]
FROM slide
ORDER BY depth DESC
FETCH FIRST ROW ONLY
;
