DROP TABLE IF EXISTS dec04;
CREATE TABLE dec04 (
    input text NOT NULL
);

\COPY dec04 (input) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/4/input';

/* FIRST STAR */

WITH RECURSIVE

generator (num) AS (
    SELECT CAST(substring(input FOR position('-' IN input)-1) AS integer)
    FROM dec04

    UNION ALL

    SELECT num + 1
    FROM generator
    WHERE num < (SELECT CAST(substring(input FROM position('-' IN input)+1) AS integer) FROM dec04)
)

SELECT count(*) AS first_star
FROM (
    /* Subquery to get each individual digit */
    SELECT num,
           num / 100000 AS d1,
           num / 10000 % 10 AS d2,
           num / 1000 % 10 AS d3,
           num / 100 % 10 AS d4,
           num / 10 % 10 AS d5,
           num % 10 AS d6
    FROM generator
) AS _
WHERE
  /* 6-digit number */
      d1 BETWEEN 1 AND 9
  /* all increasing */
  AND d1 <= d2
  AND d2 <= d3
  AND d3 <= d4
  AND d4 <= d5
  AND d5 <= d6
  /* has double */
  AND (d1 = d2 OR d2 = d3 OR d3 = d4 OR d4 = d5 OR d5 = d6)
;

/* SECOND STAR */

WITH RECURSIVE

generator (num) AS (
    SELECT CAST(substring(input FOR position('-' IN input)-1) AS integer)
    FROM dec04

    UNION ALL

    SELECT num + 1
    FROM generator
    WHERE num < (SELECT CAST(substring(input FROM position('-' IN input)+1) AS integer) FROM dec04)
)

SELECT count(*) AS second_star
FROM (
    /* Subquery to get each individual digit */
    SELECT num,
           num / 100000 AS d1,
           num / 10000 % 10 AS d2,
           num / 1000 % 10 AS d3,
           num / 100 % 10 AS d4,
           num / 10 % 10 AS d5,
           num % 10 AS d6
    FROM generator
) AS _
WHERE
  /* 6-digit number */
      d1 BETWEEN 1 AND 9
  /* all increasing */
  AND d1 <= d2
  AND d2 <= d3
  AND d3 <= d4
  AND d4 <= d5
  AND d5 <= d6
  /* has at least one double that isn't a triple or more */
  AND (             d1 = d2 AND d2 <> d3 OR
       d1 <> d2 AND d2 = d3 AND d3 <> d4 OR
       d2 <> d3 AND d3 = d4 AND d4 <> d5 OR
       d3 <> d4 AND d4 = d5 AND d5 <> d6 OR
       d4 <> d5 AND d5 = d6)
;
