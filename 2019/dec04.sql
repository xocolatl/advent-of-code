DROP TABLE IF EXISTS dec04;
CREATE TABLE dec04 (
    input text NOT NULL
);

\COPY dec04 (input) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/4/input';
VACUUM ANALYZE dec04;

/* FIRST STAR */

SELECT  count(*)
FROM    (SELECT CAST(substring(input FOR  position('-' IN input)-1) AS integer) AS l,
                CAST(substring(input FROM position('-' IN input)+1) AS integer) AS u
         FROM dec04) AS i,
LATERAL (WITH RECURSIVE d1 (d1) AS (VALUES ( 1) UNION ALL SELECT d1+1 FROM d1 WHERE d1 < 9) TABLE d1) AS d1,
LATERAL (WITH RECURSIVE d2 (d2) AS (VALUES (d1) UNION ALL SELECT d2+1 FROM d2 WHERE d2 < 9) TABLE d2) AS d2,
LATERAL (WITH RECURSIVE d3 (d3) AS (VALUES (d2) UNION ALL SELECT d3+1 FROM d3 WHERE d3 < 9) TABLE d3) AS d3,
LATERAL (WITH RECURSIVE d4 (d4) AS (VALUES (d3) UNION ALL SELECT d4+1 FROM d4 WHERE d4 < 9) TABLE d4) AS d4,
LATERAL (WITH RECURSIVE d5 (d5) AS (VALUES (d4) UNION ALL SELECT d5+1 FROM d5 WHERE d5 < 9) TABLE d5) AS d5,
LATERAL (WITH RECURSIVE d6 (d6) AS (VALUES (d5) UNION ALL SELECT d6+1 FROM d6 WHERE d6 < 9) TABLE d6) AS d6
WHERE (100000*d1 + 10000*d2 + 1000*d3 + 100*d4 + 10*d5 + d6) BETWEEN l AND u
  AND (d1 = d2 OR d2 = d3 OR d3 = d4 OR d4 = d5 OR d5 = d6)
;

/* SECOND STAR */

SELECT  count(*)
FROM    (SELECT CAST(substring(input FOR  position('-' IN input)-1) AS integer) AS l,
                CAST(substring(input FROM position('-' IN input)+1) AS integer) AS u
         FROM dec04) AS i,
LATERAL (WITH RECURSIVE d1 (d1) AS (VALUES ( 1) UNION ALL SELECT d1+1 FROM d1 WHERE d1 < 9) TABLE d1) AS d1,
LATERAL (WITH RECURSIVE d2 (d2) AS (VALUES (d1) UNION ALL SELECT d2+1 FROM d2 WHERE d2 < 9) TABLE d2) AS d2,
LATERAL (WITH RECURSIVE d3 (d3) AS (VALUES (d2) UNION ALL SELECT d3+1 FROM d3 WHERE d3 < 9) TABLE d3) AS d3,
LATERAL (WITH RECURSIVE d4 (d4) AS (VALUES (d3) UNION ALL SELECT d4+1 FROM d4 WHERE d4 < 9) TABLE d4) AS d4,
LATERAL (WITH RECURSIVE d5 (d5) AS (VALUES (d4) UNION ALL SELECT d5+1 FROM d5 WHERE d5 < 9) TABLE d5) AS d5,
LATERAL (WITH RECURSIVE d6 (d6) AS (VALUES (d5) UNION ALL SELECT d6+1 FROM d6 WHERE d6 < 9) TABLE d6) AS d6
WHERE (100000*d1 + 10000*d2 + 1000*d3 + 100*d4 + 10*d5 + d6) BETWEEN l AND u
  AND (             d1 = d2 AND d2 <> d3 OR
       d1 <> d2 AND d2 = d3 AND d3 <> d4 OR
       d2 <> d3 AND d3 = d4 AND d4 <> d5 OR
       d3 <> d4 AND d4 = d5 AND d5 <> d6 OR
       d4 <> d5 AND d5 = d6)
;
