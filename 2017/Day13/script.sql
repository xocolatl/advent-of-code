CREATE TABLE day13 (rownum serial, input text);

\COPY day13 (input) FROM 'input.txt'

WITH
input AS (
    SELECT match[1]::integer AS depth,
           match[2]::integer AS range
    FROM day13,
         regexp_match(input, '^(\d+): (\d+)$') AS match
)
SELECT sum(depth * range) FILTER (WHERE depth % (2*(range-1)) = 0) AS first_star
FROM input;

WITH RECURSIVE
input AS (
    SELECT match[1]::integer AS depth,
           match[2]::integer AS range
    FROM day13,
         regexp_match(input, '^(\d+): (\d+)$') AS match
),
loop AS (
    SELECT 0 AS delay
    UNION ALL
    SELECT delay+1
    FROM loop
    WHERE EXISTS (SELECT FROM input WHERE (depth+delay) % (2*(range-1)) = 0)
)
SELECT max(delay) AS second_star
FROM loop;

DROP TABLE day13;
