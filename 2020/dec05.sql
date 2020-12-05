DROP TABLE IF EXISTS dec05;
CREATE TABLE dec05 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    pass text NOT NULL
);

\COPY dec05 (pass) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/5/input';
VACUUM ANALYZE dec05;

\timing on

/* FIRST STAR */

SELECT max(8*row + col)
FROM dec05,
     LATERAL (VALUES (
        CAST(CAST(translate(SUBSTRING(pass FROM 1 FOR 7), 'FB', '01') AS bit(7)) AS integer),
        CAST(CAST(translate(SUBSTRING(pass FROM 8 FOR 3), 'LR', '01') AS bit(3)) AS integer)
     )) AS v (row, col)
;

/* SECOND STAR */

SELECT id-1
FROM (
    SELECT id, lag(id) OVER w
    FROM dec05,
         LATERAL (VALUES (
            CAST(CAST(translate(SUBSTRING(pass FROM 1 FOR 7), 'FB', '01') AS bit(7)) AS integer),
            CAST(CAST(translate(SUBSTRING(pass FROM 8 FOR 3), 'LR', '01') AS bit(3)) AS integer)
         )) AS v (row, col),
         LATERAL (VALUES (8*row + col)) AS v2 (id)
    WINDOW w AS (ORDER BY id)
) AS _
WHERE id <> lag+1
;
