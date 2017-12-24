CREATE TABLE day24 (rownum serial, input text);

\COPY day24 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT rownum,
           match[1]::integer AS a,
           match[2]::integer AS b
    FROM day24,
         regexp_match(input, '^(\d+)/(\d+)$') AS match
),
bridges AS (
    SELECT 0 AS step,
           rownum,
           0 AS a,
           greatest(a, b) AS b,
           array[rownum] AS path,
           a + b AS strength
    FROM input
    WHERE a = 0 OR b = 0
    UNION ALL
    SELECT b.step+1,
           i.rownum,
           b.b,
           i.a + i.b - b.b,
           path || i.rownum,
           b.strength + i.a + i.b
    FROM input AS i
    JOIN bridges AS b ON b.b IN (i.a, i.b)
    WHERE i.rownum <> ALL (b.path)
),
first_star AS (
    SELECT max(strength) AS first_star
    FROM bridges
),
second_star AS (
    SELECT strength AS second_star
    FROM bridges
    ORDER BY step DESC, strength DESC
    LIMIT 1
)
SELECT (TABLE first_star),
       (TABLE second_star);

DROP TABLE day24;
