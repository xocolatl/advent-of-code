DROP TABLE IF EXISTS dec12;
CREATE TABLE dec12 (
    moon integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    coords text NOT NULL
);

\COPY dec12 (coords) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/12/input';
VACUUM ANALYZE dec12;

/* FIRST STAR */

WITH RECURSIVE

input (moon, x, y, z) AS (
    SELECT moon, CAST(r[1] AS integer), CAST(r[2] AS integer), CAST(r[3] AS integer)
    FROM dec12
    CROSS JOIN LATERAL regexp_matches(coords, '^<x=(-?\d+), y=(-?\d+), z=(-?\d+)>$') AS r
),

runner (tick, x, y, z, vx, vy, vz) AS (
    SELECT 0,
           array_agg(x ORDER BY moon),
           array_agg(y ORDER BY moon),
           array_agg(z ORDER BY moon),
           ARRAY[0, 0, 0, 0],
           ARRAY[0, 0, 0, 0],
           ARRAY[0, 0, 0, 0]
    FROM input

    UNION ALL

    (WITH -- This is oddly not valid Standard SQL
     data (tick, x, y, z, vx, vy, vz, moon) AS (
         SELECT tick, u.*
         FROM runner
         CROSS JOIN LATERAL unnest(x, y, z, vx, vy, vz) WITH ORDINALITY AS u
     )
     SELECT tick+1,
            array_agg(data.x + data.vx + d.vx ORDER BY moon),
            array_agg(data.y + data.vy + d.vy ORDER BY moon),
            array_agg(data.z + data.vz + d.vz ORDER BY moon),
            array_agg(data.vx + d.vx ORDER BY moon),
            array_agg(data.vy + d.vy ORDER BY moon),
            array_agg(data.vz + d.vz ORDER BY moon)
     FROM data
     CROSS JOIN LATERAL (
         SELECT CAST(sum(CASE WHEN data.x < d.x THEN +1
                              WHEN data.x > d.x THEN -1
                         ELSE 0
                         END) AS integer),
                CAST(sum(CASE WHEN data.y < d.y THEN +1
                              WHEN data.y > d.y THEN -1
                         ELSE 0
                         END) AS integer),
                CAST(sum(CASE WHEN data.z < d.z THEN +1
                              WHEN data.z > d.z THEN -1
                         ELSE 0
                         END) AS integer)
         FROM data AS d
         WHERE d.moon <> data.moon
     ) AS d (vx, vy, vz)
     WHERE tick < 1000
     GROUP BY tick
    )
)

SELECT sum((abs(u.x)+abs(u.y)+abs(u.z)) * (abs(u.vx)+abs(u.vy)+abs(u.vz))) AS first_star
FROM runner
CROSS JOIN LATERAL unnest(x, y, z, vx, vy, vz) u(x, y, z, vx, vy, vz)
WHERE tick = 1000
;

/* SECOND STAR */

WITH RECURSIVE

input (moon, x, y, z) AS (
    SELECT moon, CAST(r[1] AS integer), CAST(r[2] AS integer), CAST(r[3] AS integer)
    FROM dec12
    CROSS JOIN LATERAL regexp_matches(coords, '^<x=(-?\d+), y=(-?\d+), z=(-?\d+)>$') AS r
),

runner (tick, x, y, z, vx, vy, vz, rx, ry, rz) AS (
    SELECT 0,
           array_agg(x ORDER BY moon),
           array_agg(y ORDER BY moon),
           array_agg(z ORDER BY moon),
           ARRAY[0, 0, 0, 0],
           ARRAY[0, 0, 0, 0],
           ARRAY[0, 0, 0, 0],
           CAST(NULL AS bigint),
           CAST(NULL AS bigint),
           CAST(NULL AS bigint)
    FROM input

    UNION ALL

    (WITH 
     data (tick, x, y, z, vx, vy, vz, moon, rx, ry, rz) AS (
         SELECT tick, u.*,

                /* Find first repeat of X */
                CASE WHEN rx IS NULL
                      AND runner.x = (SELECT array_agg(x ORDER BY moon) FROM input)
                      AND runner.vx = ARRAY[0, 0, 0, 0]
                      AND tick > 0
                     THEN tick
                     ELSE rx
                END,

                /* Find first repeat of Y */
                CASE WHEN ry IS NULL
                      AND runner.y = (SELECT array_agg(y ORDER BY moon) FROM input)
                      AND runner.vy = ARRAY[0, 0, 0, 0]
                      AND tick > 0
                     THEN tick
                     ELSE ry
                END,

                /* Find first repeat of Z */
                CASE WHEN rz IS NULL
                      AND runner.z = (SELECT array_agg(z ORDER BY moon) FROM input)
                      AND runner.vz = ARRAY[0, 0, 0, 0]
                      AND tick > 0
                     THEN tick
                     ELSE rz
                END

         FROM runner
         CROSS JOIN LATERAL unnest(x, y, z, vx, vy, vz) WITH ORDINALITY AS u
     )

     SELECT tick+1,
            array_agg(data.x + data.vx + d.vx ORDER BY moon),
            array_agg(data.y + data.vy + d.vy ORDER BY moon),
            array_agg(data.z + data.vz + d.vz ORDER BY moon),
            array_agg(data.vx + d.vx ORDER BY moon),
            array_agg(data.vy + d.vy ORDER BY moon),
            array_agg(data.vz + d.vz ORDER BY moon),
            rx, ry, rz
     FROM data
     CROSS JOIN LATERAL (
         SELECT CAST(sum(CASE WHEN data.x < d.x THEN +1
                              WHEN data.x > d.x THEN -1
                         ELSE 0
                         END) AS integer),
                CAST(sum(CASE WHEN data.y < d.y THEN +1
                              WHEN data.y > d.y THEN -1
                         ELSE 0
                         END) AS integer),
                CAST(sum(CASE WHEN data.z < d.z THEN +1
                              WHEN data.z > d.z THEN -1
                         ELSE 0
                         END) AS integer)
         FROM data AS d
         WHERE d.moon <> data.moon
     ) AS d (vx, vy, vz)
     GROUP BY tick, rx, ry, rz
    )
)

SELECT xyz AS second_star
FROM (
    SELECT *
    FROM runner
    WHERE rx IS NOT NULL
      AND ry IS NOT NULL
      AND rz IS NOT NULL
    FETCH FIRST ROW ONLY
) AS runner

/* lcm(rx, ry) */
CROSS JOIN LATERAL (
    WITH RECURSIVE
    gcd (a, b, d) AS (
        SELECT rx, ry, CAST(1 AS bigint)
        UNION ALL
        SELECT CASE WHEN a%2=0 THEN a/2 
                    WHEN b%2<>0 AND a>b THEN (a-b)/2
               ELSE a END,
               CASE WHEN b%2=0 THEN b/2
                    WHEN a%2<>0 AND b>a THEN (b-a)/2
               ELSE b END,
               CASE WHEN a%2=0 AND b%2=0 THEN d*2 ELSE d END
        FROM gcd
        WHERE a <> b
    )
    SELECT (rx * ry) / (a * d)
    FROM gcd
    WHERE a = b
) AS lcm_xy(xy)

/* lcm(lcm(rx, ry), rz) */
CROSS JOIN LATERAL (
    WITH RECURSIVE
    gcd (a, b, d) AS (
        SELECT xy, rz, CAST(1 AS bigint)
        UNION ALL
        SELECT CASE WHEN a%2=0 THEN a/2 
                    WHEN b%2<>0 AND a>b THEN (a-b)/2
               ELSE a END,
               CASE WHEN b%2=0 THEN b/2
                    WHEN a%2<>0 AND b>a THEN (b-a)/2
               ELSE b END,
               CASE WHEN a%2=0 AND b%2=0 THEN d*2 ELSE d END
        FROM gcd
        WHERE a <> b
    )
    SELECT (xy * rz) / (a * d)
    FROM gcd
    WHERE a = b
) AS lcm_xyz(xyz)
;
