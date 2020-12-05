DROP TABLE IF EXISTS dec05;
CREATE TABLE dec05 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    pass text NOT NULL
);

\COPY dec05 (pass) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/5/input';
VACUUM ANALYZE dec05;

\timing on

/* FIRST STAR */

SELECT max(CAST(CAST(translate(pass, 'FBLR', '0101') AS bit(10)) AS integer))
FROM dec05
;

/* SECOND STAR */

SELECT id-1
FROM (
    SELECT id, lag(id) OVER w
    FROM dec05,
         LATERAL (VALUES (
            CAST(CAST(translate(pass, 'FBLR', '0101') AS bit(10)) AS integer)
         )) AS v (id)
    WINDOW w AS (ORDER BY id)
) AS _
WHERE id <> lag+1
;
