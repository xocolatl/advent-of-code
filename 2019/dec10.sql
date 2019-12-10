DROP TABLE IF EXISTS dec10;
CREATE TABLE dec10 (
    y integer NOT NULL GENERATED ALWAYS AS IDENTITY (MINVALUE 0),
    xs text NOT NULL
);

\COPY dec10 (xs) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/10/input';
VACUUM ANALYZE dec10;

/* FIRST STAR */

WITH

input (x, y) AS (
    WITH RECURSIVE
    runner (x, y, asteroid, xs) AS (
        SELECT 0, y, substring(xs FOR 1), substring(xs FROM 2) FROM dec10
        UNION ALL
        SELECT x+1, y, substring(xs FOR 1), substring(xs FROM 2) FROM runner WHERE xs <> ''
    )
    SELECT x, y FROM runner WHERE asteroid = '#'
)

SELECT count(DISTINCT atan2(b.y-a.y, b.x-a.x)) AS first_star
FROM input AS a
CROSS JOIN input AS b
WHERE (a.x, a.y) <> (b.x, b.y)
GROUP BY a.x, a.y
ORDER BY first_star DESC
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

WITH

input (x, y) AS (
    WITH RECURSIVE
    runner (x, y, asteroid, xs) AS (
        SELECT 0, y, substring(xs FOR 1), substring(xs FROM 2) FROM dec10
        UNION ALL
        SELECT x+1, y, substring(xs FOR 1), substring(xs FROM 2) FROM runner WHERE xs <> ''
    )
    SELECT x, y FROM runner WHERE asteroid = '#'
),

station (x, y) AS (
    -- This is basically part one
    SELECT a.x, a.y
    FROM input AS a
    CROSS JOIN input AS b
    WHERE (a.x, a.y) <> (b.x, b.y)
    GROUP BY a.x, a.y
    ORDER BY count(DISTINCT atan2(b.y-a.y, b.x-a.x)) DESC
    FETCH FIRST ROW ONLY
)

SELECT 100 * x + y AS second_star
FROM (
    SELECT x, y,
           row_number() OVER w AS loop,
           CASE WHEN 450+angle >= 360 THEN 90+angle ELSE 450+angle END AS angle
    FROM (
        SELECT b.x, b.y,
               degrees(atan2(b.y-a.y, b.x-a.x)) AS angle,
               sqrt((b.y-a.y)*(b.y-a.y) + (b.x-a.x)*(b.x-a.x)) AS distance
        FROM station AS a
        CROSS JOIN input AS b
        WHERE (a.x, a.y) <> (b.x, b.y)
    ) AS _
    WINDOW w AS (PARTITION BY angle ORDER BY distance)
) AS _
ORDER BY loop, angle
OFFSET 199 -- don't @ me
FETCH FIRST ROW ONLY
;
