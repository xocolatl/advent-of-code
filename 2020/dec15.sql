DROP TABLE IF EXISTS dec15;
CREATE TABLE dec15 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec15 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/15/input';
VACUUM ANALYZE dec15;

\timing on

/* FIRST STAR */

WITH RECURSIVE

input AS (
    SELECT o,
           CAST(n AS bigint),
           jsonb_object_agg(n, o) OVER w
    FROM dec15,
         regexp_split_to_table(line, ',') WITH ORDINALITY AS rx (n, o)
         WINDOW w AS (ORDER BY o ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
    ORDER BY o DESC
    FETCH FIRST ROW ONLY
),

runner (iter, prev, cache) AS (
    TABLE input

    UNION ALL

    SELECT r.iter+1,
           v.prev,
           r.cache || jsonb_build_object(r.prev, r.iter)
    FROM runner AS r,
         LATERAL (VALUES (
            CASE WHEN r.cache ? CAST(r.prev AS text) THEN
                r.iter - CAST(r.cache->>CAST(r.prev AS text) AS bigint)
            ELSE 0
            END
         )) AS v (prev)
    WHERE r.iter < 2020
)

SELECT prev
FROM runner
WHERE iter = 2020
;

/* SECOND STAR */

WITH RECURSIVE

input AS (
    SELECT o,
           CAST(n AS bigint),
           jsonb_object_agg(n, o) OVER w
    FROM dec15,
         regexp_split_to_table(line, ',') WITH ORDINALITY AS rx (n, o)
         WINDOW w AS (ORDER BY o ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)
    ORDER BY o DESC
    FETCH FIRST ROW ONLY
),

runner (iter, prev, cache) AS (
    TABLE input

    UNION ALL

    SELECT r3.iter, r3.prev, r3.cache
    FROM runner AS r2,
         LATERAL (VALUES (r2.iter, r2.iter+1000, 30000000)) AS v (start, stop, final)
    CROSS JOIN LATERAL (
        WITH RECURSIVE
        runner (iter, prev, cache) AS (
            VALUES (v.start, r2.prev, r2.cache)
            UNION ALL
            SELECT r.iter+1,
                   CASE WHEN r.cache ? CAST(r.prev AS text) THEN
                       r.iter - CAST(r.cache->>CAST(r.prev AS text) AS bigint)
                   ELSE 0
                   END,
                   r.cache || jsonb_build_object(r.prev, r.iter)
            FROM runner AS r
            WHERE r.iter < LEAST(stop, final)
        )
        SELECT *
        FROM runner
        ORDER BY iter DESC
        FETCH FIRST ROW ONLY
    ) AS r3
    WHERE r2.iter < final
),

main AS (
    SELECT prev
    FROM runner
    WHERE iter = 30000000
)

SELECT
E'This solution works but takes forever.  It took over seven hours to\n'
 'generate the 1 millionth iteration, so letting it go to 30 million\n'
 'is inconceivable.  However, I did invent a nice trick to calculate\n'
 'them in batches so I didn''t also run out of memory!\n'
 '\n'
 'Change this to  SELECT * FROM main  if you''d like to try it anyway.'
;
