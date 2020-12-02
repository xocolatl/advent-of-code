DROP TABLE IF EXISTS dec02;
CREATE TABLE dec02 (
    line_number bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec02 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/2/input';
VACUUM ANALYZE dec01;

\timing on

/* FIRST STAR */

WITH

input (min, max, letter, password) AS (
    SELECT CAST(r[1] AS integer),
           CAST(r[2] AS integer),
           r[3],
           r[4]
    FROM dec02 AS d,
         LATERAL regexp_match(d.line, '^(\d+)-(\d+) (\w): (\w+)$') AS r
)

SELECT count(*)
FROM input
WHERE cardinality(array_positions(string_to_array(password, NULL), letter)) BETWEEN min AND max
;

/* SECOND STAR */

WITH

input (pos1, pos2, letter, password) AS (
    SELECT CAST(r[1] AS integer),
           CAST(r[2] AS integer),
           r[3],
           r[4]
    FROM dec02 AS d,
         LATERAL regexp_match(d.line, '^(\d+)-(\d+) (\w): (\w+)$') AS r
)

SELECT count(*)
FROM input AS i,
     LATERAL string_to_array(i.password, NULL) AS _ (a)
WHERE i.letter IN (a[pos1], a[pos2])
  AND a[pos1] <> a[pos2]
;
