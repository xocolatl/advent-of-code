CREATE TABLE day07 (input text);

\COPY day07 FROM 'input.txt'

WITH
input (name, weight, supporting) AS (
    SELECT match[1],
           match[2]::integer,
           string_to_array(match[3], ', ')::text[]
    FROM day07,
         regexp_match(input, '(\w+) \((\d+)\)(?: -> (.*))?') AS match
)
SELECT name AS first_star
FROM input
WHERE NOT EXISTS (
    SELECT FROM input AS parent
    WHERE input.name = ANY (parent.supporting));

DROP TABLE day07;
