DROP TABLE IF EXISTS dec12;
CREATE TABLE dec12 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec12 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/12/input';
VACUUM ANALYZE dec12;

\timing on

/* FIRST STAR */

WITH RECURSIVE

sailor (iter, x, y, dx, dy) AS (
    VALUES (0, 0, 0, 1, 0)

    UNION ALL

    SELECT s.iter+1,

           /* x */
           CASE m.action WHEN 'F' THEN s.x + m.amount * s.dx
                         WHEN 'E' THEN s.x + m.amount
                         WHEN 'W' THEN s.x - m.amount
                         ELSE s.x
           END,

           /* y */
           CASE m.action WHEN 'F' THEN s.y + m.amount * s.dy
                         WHEN 'N' THEN s.y - m.amount
                         WHEN 'S' THEN s.y + m.amount
                         ELSE s.y
           END,

           /* dx */
           CASE m.action
            WHEN 'L' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dx
                    WHEN  90 THEN s.dy
                    WHEN 180 THEN -s.dx
                    WHEN 270 THEN -s.dy
                END
            WHEN 'R' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dx
                    WHEN  90 THEN -s.dy
                    WHEN 180 THEN -s.dx
                    WHEN 270 THEN s.dy
                END
            ELSE s.dx
           END,

           /* dy */
           CASE m.action
            WHEN 'L' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dy
                    WHEN  90 THEN -s.dx
                    WHEN 180 THEN -s.dy
                    WHEN 270 THEN s.dx
                END
            WHEN 'R' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dy
                    WHEN  90 THEN s.dx
                    WHEN 180 THEN -s.dy
                    WHEN 270 THEN -s.dx
                END
            ELSE s.dy
           END
    FROM sailor AS s
    JOIN dec12 AS d ON d.line_number = s.iter+1
    CROSS JOIN LATERAL (
        SELECT m[1], CAST(m[2] AS integer)
        FROM regexp_match(d.line, '^([NSEWLRF])(\d+)$') AS m
    ) AS m (action, amount)

)

SELECT abs(x) + abs(y)
FROM sailor
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

WITH RECURSIVE

sailor (iter, x, y, dx, dy) AS (
    VALUES (0, 0, 0, 10, -1)

    UNION ALL

    SELECT s.iter+1,

           /* x */
           CASE m.action
               WHEN 'F' THEN s.x + m.amount * s.dx
               ELSE s.x
           END,

           /* y */
           CASE m.action
               WHEN 'F' THEN s.y + m.amount * s.dy
               ELSE s.y
           END,

           /* dx */
           CASE m.action
            WHEN 'E' THEN s.dx + m.amount
            WHEN 'W' THEN s.dx - m.amount
            WHEN 'L' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dx
                    WHEN  90 THEN s.dy
                    WHEN 180 THEN -s.dx
                    WHEN 270 THEN -s.dy
                END
            WHEN 'R' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dx
                    WHEN  90 THEN -s.dy
                    WHEN 180 THEN -s.dx
                    WHEN 270 THEN s.dy
                END
            ELSE s.dx
           END,

           /* dy */
           CASE m.action
            WHEN 'N' THEN s.dy - m.amount
            WHEN 'S' THEN s.dy + m.amount
            WHEN 'L' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dy
                    WHEN  90 THEN -s.dx
                    WHEN 180 THEN -s.dy
                    WHEN 270 THEN s.dx
                END
            WHEN 'R' THEN
                CASE m.amount % 360
                    WHEN   0 THEN s.dy
                    WHEN  90 THEN s.dx
                    WHEN 180 THEN -s.dy
                    WHEN 270 THEN -s.dx
                END
            ELSE s.dy
           END
    FROM sailor AS s
    JOIN dec12 AS d ON d.line_number = s.iter+1
    CROSS JOIN LATERAL (
        SELECT m[1], CAST(m[2] AS integer)
        FROM regexp_match(d.line, '^([NSEWLRF])(\d+)$') AS m
    ) AS m (action, amount)

)

SELECT abs(x) + abs(y)
FROM sailor
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;
