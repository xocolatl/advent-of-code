DROP TABLE IF EXISTS dec11;
CREATE TABLE dec11 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec11 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/11/input';
VACUUM ANALYZE dec11;

\timing on

/* FIRST STAR */

WITH RECURSIVE

runner (iter, seats, prev_seats) AS (
    SELECT 0, string_agg(line, '' ORDER BY line_number), NULL
    FROM dec11

    UNION ALL

    SELECT r.iter+1,
           f.seats,
           r.seats
    FROM runner AS r,
         LATERAL (
            SELECT string_agg(
                       CASE
                           WHEN t.seat = '#' THEN
                               CASE WHEN occupied_seats < 4 THEN '#' ELSE 'L' END
                           WHEN t.seat = 'L' THEN
                               CASE WHEN occupied_seats = 0 THEN '#' ELSE 'L' END
                           ELSE t.seat
                       END,
                       ''
                       ORDER BY t.idx)
            FROM (
                SELECT t.idx, t.seat, num_nonnulls(
                   NULLIF(lag(seat,  98+1) OVER (ORDER BY idx) = '#' AND NOT left_side,  false),
                   NULLIF(lag(seat,  98+0) OVER (ORDER BY idx) = '#',                    false),
                   NULLIF(lag(seat,  98-1) OVER (ORDER BY idx) = '#' AND NOT right_side, false),
                   NULLIF(lag(seat,     1) OVER (ORDER BY idx) = '#' AND NOT left_side,  false),
                   NULLIF(lead(seat,    1) OVER (ORDER BY idx) = '#' AND NOT right_side, false),
                   NULLIF(lead(seat, 98-1) OVER (ORDER BY idx) = '#' AND NOT left_side,  false),
                   NULLIF(lead(seat, 98+0) OVER (ORDER BY idx) = '#',                    false),
                   NULLIF(lead(seat, 98+1) OVER (ORDER BY idx) = '#' AND NOT right_side, false)) AS occupied_seats
                FROM regexp_split_to_table(r.seats, '') WITH ORDINALITY AS t (seat, idx),
                     LATERAL (VALUES ((idx-1) % 98 = 0, (idx-1) % 98 = 97)) AS v (left_side, right_side)
            ) AS t
         ) AS f (seats)
    WHERE f.seats <> r.seats
)

SELECT length(translate(seats, '.L', ''))
FROM runner
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

WITH RECURSIVE

runner (iter, seats, prev_seats) AS (
    SELECT 0, string_agg(line, '' ORDER BY line_number), NULL
    FROM dec11

    UNION ALL

    SELECT r.iter+1,
           f.seats,
           r.seats
    FROM runner AS r,
         LATERAL (
            SELECT string_agg(
                    CASE q2.seat
                        WHEN '#' THEN
                            CASE WHEN occupied_seats < 5 THEN '#' ELSE 'L' END
                        WHEN 'L' THEN
                            CASE WHEN occupied_seats = 0 THEN '#' ELSE 'L' END
                        ELSE q2.seat
                    END,
                    ''
                    ORDER BY q2.idx) AS seats
            FROM (
                SELECT t.idx, t.seat, count(*) FILTER (WHERE q1.occupied) AS occupied_seats
                FROM regexp_split_to_table(r.seats, '') WITH ORDINALITY AS t (seat, idx),
                     (VALUES (-1, -1), ( 0, -1), ( 1, -1),
                             (-1,  0),           ( 1,  0),
                             (-1,  1), ( 0,  1), ( 1,  1)
                     ) AS dxy (dx, dy),
                     LATERAL (
                        WITH RECURSIVE

                        tracer (iter, seats, x, y, dx, dy, found, occupied) AS (
                            SELECT 0,
                                   r.seats,
                                   CAST((t.idx-1) % 98 + dxy.dx AS integer),
                                   CAST((t.idx-1) / 98 + dxy.dy AS integer),
                                   dxy.dx,
                                   dxy.dy,
                                   false,
                                   false

                            UNION ALL

                            SELECT iter+1, seats,
                                   x+dx, y+dy,
                                   dx, dy,
                                   SUBSTRING(seats FROM x + 98*y + 1 FOR 1) <> '.',
                                   SUBSTRING(seats FROM x + 98*y + 1 FOR 1) = '#'
                            FROM tracer
                            WHERE x BETWEEN 0 AND 97
                              AND y BETWEEN 0 AND 96
                              AND NOT found
                        )

                        SELECT occupied
                        FROM tracer
                        ORDER BY iter DESC
                        FETCH FIRST ROW ONLY
                     ) AS q1
                 GROUP BY t.idx, t.seat
             ) AS q2
         ) AS f
    WHERE f.seats <> r.seats
)

SELECT length(translate(seats, '.L', ''))
FROM runner
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;
