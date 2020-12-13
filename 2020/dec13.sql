DROP TABLE IF EXISTS dec13;
CREATE TABLE dec13 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec13 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/13/input';
VACUUM ANALYZE dec13;

\timing on

/* FIRST STAR */

WITH

ts (time) AS (
    SELECT CAST(line AS integer)
    FROM dec13
    WHERE line_number = 1
),

buses (id) AS (
    SELECT CAST(ids.id AS integer)
    FROM dec13 AS d,
         LATERAL regexp_split_to_table(line, ',') AS ids (id)
    WHERE d.line_number = 2
      AND ids.id <> 'x'
),

passages (id, minutes) AS (
    SELECT b.id, b.id - (ts.time % b.id)
    FROM ts, buses AS b
)

SELECT id * minutes
FROM passages
ORDER BY minutes
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

WITH RECURSIVE

input (idx, bus, magic) AS (
    SELECT idx, bus, (bus - ((idx-1) % bus)) % bus
    FROM dec13 AS d,
         LATERAL regexp_split_to_table(d.line, ',') WITH ORDINALITY AS r (sbus, idx),
         LATERAL (VALUES (CAST(sbus AS bigint))) AS v (bus)
    WHERE d.line_number = 2
      AND sbus <> 'x'
),

lapse (iter, time, step, bus) AS (
    SELECT 0,
           CAST(0 AS bigint),
           CAST(1 AS bigint),
           max(bus)+1
    FROM input

    UNION ALL

    SELECT l.iter + 1,
           w.time,
           w.step * i.bus,
           i.bus
    FROM lapse AS l,

         LATERAL (
            SELECT *
            FROM input AS i
            WHERE i.bus < l.bus
            ORDER BY i.bus DESC
            FETCH FIRST ROW ONLY
         ) AS i,

         LATERAL (
            WITH RECURSIVE
            while (iter, time, step) AS (
                VALUES (0, l.time, l.step)
                UNION ALL
                SELECT iter+1, time + step, step
                FROM while
                WHERE time % i.bus <> i.magic
            )
            SELECT while.time, while.step
            FROM while
            ORDER BY while.iter DESC
            FETCH FIRST ROW ONLY
         ) AS w
    WHERE l.iter < 10
)

SELECT time
FROM lapse
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;
