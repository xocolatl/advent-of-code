DROP TABLE IF EXISTS dec01;
CREATE TABLE dec01 (
    line_number bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    value bigint NOT NULL
);

\COPY dec01 (value) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/1/input';
VACUUM ANALYZE dec01;

CREATE INDEX ON dec01 (value, line_number);

\timing on

/* FIRST STAR */

SELECT a.value * b.value
FROM dec01 AS a,
     dec01 AS b
WHERE a.line_number < b.line_number
  AND b.value = 2020 - a.value
;

/* SECOND STAR */

SELECT a.value * b.value * c.value
FROM dec01 AS a,
     dec01 AS b,
     dec01 AS c
WHERE a.line_number < b.line_number
  AND b.line_number < c.line_number
  AND b.value <= 2020 - a.value
  AND c.value = 2020 - a.value - b.value
;
