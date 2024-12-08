CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec07;

CREATE TABLE dec07 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec07 (line) FROM '2024/dec07.input' NULL ''
VACUUM ANALYZE dec07;

/**************/
/* FIRST STAR */
/**************/

WITH RECURSIVE

input (line_number, total, operands) AS (
    SELECT line_number,
           CAST(split_part(line, ': ', 1) AS NUMERIC),
           CAST(string_to_array(split_part(line, ': ', 2), ' ') AS NUMERIC ARRAY)
    FROM dec07
),

loop AS (
    SELECT 0 AS step,
           line_number,
           total,
           operands[1] AS result,
           operands[2:] AS operands
    FROM input

    UNION ALL

    SELECT l.step + 1,
           l.line_number,
           l.total,
           CASE op
               WHEN '+' THEN l.result + l.operands[1]
               WHEN '*' THEN l.result * l.operands[1]
           END,
           l.operands[2:]
    FROM loop AS l
    CROSS JOIN (VALUES ('+'), ('*')) AS operators (op)
    WHERE CARDINALITY(l.operands) > 0
),

possibles (line_number, total) AS (
    SELECT line_number, ANY_VALUE(total)
    FROM loop
    WHERE total = result
      AND CARDINALITY(operands) = 0
    GROUP BY line_number
)

SELECT SUM(total) AS first_star
FROM possibles
;

/***************/
/* SECOND STAR */
/***************/
 
WITH RECURSIVE

input (line_number, total, operands) AS (
    SELECT line_number,
           CAST(split_part(line, ': ', 1) AS NUMERIC),
           CAST(string_to_array(split_part(line, ': ', 2), ' ') AS NUMERIC ARRAY)
    FROM dec07
),

loop AS (
    SELECT 0 AS step,
           line_number,
           total,
           operands[1] AS result,
           operands[2:] AS operands
    FROM input

    UNION ALL

    SELECT l.step + 1,
           l.line_number,
           l.total,
           CASE op
               WHEN '+'  THEN l.result + l.operands[1]
               WHEN '*'  THEN l.result * l.operands[1]
               WHEN '||' THEN CAST(CAST(l.result AS text) || CAST(l.operands[1] AS text) AS NUMERIC)
           END,
           l.operands[2:]
    FROM loop AS l
    CROSS JOIN (VALUES ('+'), ('*'), ('||')) AS operators (op)
    WHERE CARDINALITY(l.operands) > 0
),

possibles (line_number, total) AS (
    SELECT line_number, ANY_VALUE(total)
    FROM loop
    WHERE total = result
      AND CARDINALITY(operands) = 0
    GROUP BY line_number
)

SELECT SUM(total) AS second_star
FROM possibles
;
