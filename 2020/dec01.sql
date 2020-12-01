DROP TABLE IF EXISTS dec01;
CREATE TABLE dec01 (
    digit bigint NOT NULL
);

\COPY dec01 (digit) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/1/input';
VACUUM ANALYZE dec01;

/* FIRST STAR */

SELECT a.digit * b.digit
FROM dec01 AS a,
     dec01 AS b
WHERE a.digit < b.digit
  AND a.digit + b.digit = 2020
;

/* SECOND STAR */

SELECT a.digit * b.digit * c.digit
FROM dec01 AS a,
     dec01 AS b,
     dec01 AS c
WHERE a.digit < b.digit
  AND b.digit < c.digit
  AND a.digit + b.digit + c.digit = 2020
;
