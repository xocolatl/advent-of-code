DROP TABLE IF EXISTS dec07;
CREATE TABLE dec07 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    rule text NOT NULL
);

\COPY dec07 (rule) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/7/input';
VACUUM ANALYZE dec07;

\timing on

/* FIRST STAR */

WITH RECURSIVE

input (parent, child) AS (
    SELECT m1[1], m3[2]
    FROM dec07 AS d,
         LATERAL regexp_match(d.rule, '^(.*) bags contain (.*)\.$') AS m1,
         LATERAL regexp_split_to_table(m1[2], ', ') AS m2,
         LATERAL regexp_match(m2, '^(\d+) (.*?) bags?$') AS m3
),

walk AS (
    SELECT *
    FROM input
    WHERE child = 'shiny gold'

    UNION ALL

    SELECT i.*
    FROM input AS i
    JOIN walk AS w ON w.parent = i.child
)

SELECT count(DISTINCT parent)
FROM walk
;

/* SECOND STAR */

WITH RECURSIVE

input (parent, count, child) AS (
    SELECT m1[1],
           COALESCE(CAST(m3[1] AS integer), 0),
           m3[2]
    FROM dec07 AS d,
         LATERAL regexp_match(d.rule, '^(.*) bags contain (.*)\.$') AS m1,
         LATERAL regexp_split_to_table(m1[2], ', ') AS m2,
         LATERAL regexp_match(m2, '^(\d+) (.*?) bags?$') AS m3
),

walk (parent, count, child) AS (
    VALUES (NULL, 1, 'shiny gold')

    UNION ALL

    SELECT i.parent,
           i.count * w.count,
           i.child
    FROM input AS i
    JOIN walk AS w ON w.child = i.parent
)

SELECT sum(count) - 1
FROM walk
;
