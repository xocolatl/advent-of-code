DROP TABLE IF EXISTS dec17;
CREATE TABLE dec17 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec17 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/17/input';
VACUUM ANALYZE dec17;

\timing on

/* FIRST STAR */

WITH RECURSIVE

input (x, y, z) AS (
    SELECT ordinality::integer, line_number, 0
    FROM dec17,
         LATERAL regexp_split_to_table(line, '') WITH ORDINALITY AS rx (c, ordinality)
    WHERE c = '#'
),

cycles (iter, x, y, z) AS (
    SELECT 0, x, y, z
    FROM input

    UNION ALL

    (
        WITH
        local_input (iter, x, y, z) AS (
            TABLE cycles
        ),

        space AS (
            SELECT x, y, z
            FROM generate_series(
                    (SELECT min(x)-1 FROM local_input),
                    (SELECT max(x)+1 FROM local_input)) AS gx (x),
                 generate_series(
                    (SELECT min(y)-1 FROM local_input),
                    (SELECT max(y)+1 FROM local_input)) AS gy (y),
                 generate_series(
                    (SELECT min(z)-1 FROM local_input),
                    (SELECT max(z)+1 FROM local_input)) AS gz (z)
        )

        SELECT i.iter+1, s.x, s.y, s.z
        FROM (SELECT iter FROM local_input FETCH FIRST ROW ONLY) AS i
        CROSS JOIN space AS s
        CROSS JOIN LATERAL (
            SELECT count(*)
            FROM generate_series(s.x-1, s.x+1) AS gx (x),
                 generate_series(s.y-1, s.y+1) AS gy (y),
                 generate_series(s.z-1, s.z+1) AS gz (z),
                 local_input AS i
            WHERE (gx.x, gy.y, gz.z) <> (s.x, s.y, s.z)
              AND (gx.x, gy.y, gz.z) = (i.x, i.y, i.z)
        ) AS active_neighbors
        WHERE i.iter < 6
          AND CASE WHEN EXISTS (SELECT FROM local_input AS i WHERE (i.x, i.y, i.z) = (s.x, s.y, s.z))
                   THEN active_neighbors.count BETWEEN 2 AND 3
                   ELSE active_neighbors.count = 3
              END
    )
)

SELECT count(*)
FROM cycles
WHERE iter = 6
;

/* SECOND STAR */

WITH RECURSIVE

input (x, y, z, w) AS (
    SELECT ordinality::integer, line_number, 0, 0
    FROM dec17,
         LATERAL regexp_split_to_table(line, '') WITH ORDINALITY AS rx (c, ordinality)
    WHERE c = '#'
),

cycles (iter, x, y, z, w) AS (
    SELECT 0, x, y, z, w
    FROM input

    UNION ALL

    (
        WITH
        local_input (iter, x, y, z, w) AS (
            TABLE cycles
        ),

        space AS (
            SELECT x, y, z, w
            FROM generate_series(
                    (SELECT min(x)-1 FROM local_input),
                    (SELECT max(x)+1 FROM local_input)) AS gx (x),
                 generate_series(
                    (SELECT min(y)-1 FROM local_input),
                    (SELECT max(y)+1 FROM local_input)) AS gy (y),
                 generate_series(
                    (SELECT min(z)-1 FROM local_input),
                    (SELECT max(z)+1 FROM local_input)) AS gz (z),
                 generate_series(
                    (SELECT min(w)-1 FROM local_input),
                    (SELECT max(w)+1 FROM local_input)) AS gw (w)
        )

        SELECT i.iter+1, s.x, s.y, s.z, s.w
        FROM (SELECT iter FROM local_input FETCH FIRST ROW ONLY) AS i
        CROSS JOIN space AS s
        CROSS JOIN LATERAL (
            SELECT count(*)
            FROM generate_series(s.x-1, s.x+1) AS gx (x),
                 generate_series(s.y-1, s.y+1) AS gy (y),
                 generate_series(s.z-1, s.z+1) AS gz (z),
                 generate_series(s.w-1, s.w+1) AS gw (w),
                 local_input AS i
            WHERE (gx.x, gy.y, gz.z, gw.w) <> (s.x, s.y, s.z, s.w)
              AND (gx.x, gy.y, gz.z, gw.w) = (i.x, i.y, i.z, i.w)
        ) AS active_neighbors
        WHERE i.iter < 6
          AND CASE WHEN EXISTS (SELECT FROM local_input AS i WHERE (i.x, i.y, i.z, i.w) = (s.x, s.y, s.z, s.w))
                   THEN active_neighbors.count BETWEEN 2 AND 3
                   ELSE active_neighbors.count = 3
              END
    )
)

SELECT count(*)
FROM cycles
WHERE iter = 6
;
