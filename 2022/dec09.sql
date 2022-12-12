CREATE SCHEMA IF NOT EXISTS aoc2022;
SET SCHEMA 'aoc2022';
DROP TABLE IF EXISTS dec09;

CREATE TABLE dec09 (
    line_number INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    line CHARACTER VARYING
);

\COPY dec09 (line) FROM '2022/dec09.input'
VACUUM ANALYZE dec09;

/* FIRST STAR */

WITH RECURSIVE

input (step, dx, dy) AS materialized (
    SELECT CAST(ROW_NUMBER() OVER (ORDER BY d.line_number, r.ordinality) AS INTEGER),
           dirs.dx,
           dirs.dy
    FROM dec09 AS d
    CROSS JOIN LATERAL regexp_matches(d.line, '^(U|R|D|L) (\d+)$') AS m
    CROSS JOIN LATERAL string_to_table(repeat(m[1], CAST(m[2] AS INTEGER)), NULL)
        WITH ORDINALITY AS r (direction, ordinality)
    JOIN (VALUES ('U',  0,  1),
                 ('R',  1,  0),
                 ('D',  0, -1),
                 ('L', -1,  0)) AS dirs (direction, dx, dy) ON dirs.direction = r.direction
),

run (step, dx, dy, hx, hy, tx, ty, visited) AS (
    VALUES (0, 0, 0, 0, 0, 0, 0, ARRAY[ROW(0, 0)])

    UNION ALL

    SELECT i.step,
           i.dx, i.dy,
           h.x, h.y,
           t.x, t.y,
           CASE WHEN ROW(t.x, t.y) = ANY (r.visited)
                THEN r.visited
                ELSE r.visited || ROW(t.x, t.y)
           END
    FROM run AS r
    JOIN input AS i ON i.step = r.step+1
    CROSS JOIN LATERAL (VALUES (r.hx + i.dx, r.hy + i.dy)) AS h (x, y)
    CROSS JOIN LATERAL (VALUES (
        CASE WHEN ABS(h.y - r.ty) = 2 THEN h.x ELSE r.tx + (h.x - r.tx) / 2 END,
        CASE WHEN ABS(h.x - r.tx) = 2 THEN h.y ELSE r.ty + (h.y - r.ty) / 2 END
    )) AS t (x, y)
)

SELECT MAX(CARDINALITY(visited)) AS first_star
FROM run
;

/* SECOND STAR */

WITH RECURSIVE

input (step, dx, dy) AS materialized (
    SELECT CAST(ROW_NUMBER() OVER (ORDER BY d.line_number, r.ordinality) AS INTEGER),
           dirs.dx,
           dirs.dy
    FROM dec09 AS d
    CROSS JOIN LATERAL regexp_matches(d.line, '^(U|R|D|L) (\d+)$') AS m
    CROSS JOIN LATERAL string_to_table(repeat(m[1], CAST(m[2] AS INTEGER)), NULL)
        WITH ORDINALITY AS r (direction, ordinality)
    JOIN (VALUES ('U',  0,  1),
                 ('R',  1,  0),
                 ('D',  0, -1),
                 ('L', -1,  0)) AS dirs (direction, dx, dy) ON dirs.direction = r.direction
),

heads (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT i.step,
           h.x + i.dx,
           h.y + i.dy
    FROM heads AS h
    JOIN input AS i ON i.step = h.step+1
),

tails (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails AS t
    JOIN heads AS h ON h.step = t.step+1
),

tails2 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails2 AS t
    JOIN tails AS h ON h.step = t.step+1
),

tails3 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails3 AS t
    JOIN tails2 AS h ON h.step = t.step+1
),

tails4 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails4 AS t
    JOIN tails3 AS h ON h.step = t.step+1
),

tails5 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails5 AS t
    JOIN tails4 AS h ON h.step = t.step+1
),

tails6 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails6 AS t
    JOIN tails5 AS h ON h.step = t.step+1
),

tails7 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails7 AS t
    JOIN tails6 AS h ON h.step = t.step+1
),

tails8 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails8 AS t
    JOIN tails7 AS h ON h.step = t.step+1
),

tails9 (step, x, y) AS (
    VALUES (0, 0, 0)

    UNION ALL

    SELECT h.step,
           CASE WHEN ABS(h.y - t.y) = 2 AND NOT ABS(h.x - t.x) = 2 THEN h.x ELSE t.x + (h.x - t.x) / 2 END,
           CASE WHEN ABS(h.x - t.x) = 2 AND NOT ABS(h.y - t.y) = 2 THEN h.y ELSE t.y + (h.y - t.y) / 2 END
    FROM tails9 AS t
    JOIN tails8 AS h ON h.step = t.step+1
)

SELECT COUNT(DISTINCT (x, y)) AS second_star
FROM tails9
;
