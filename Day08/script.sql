CREATE TABLE day08 (rownum serial, input text);

\COPY day08 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT d.rownum,
           match[1] AS register,
           CASE match[2]
               WHEN 'inc' THEN +1
               WHEN 'dec' THEN -1
           END AS sign,
           match[3]::integer AS diff,
           match[4] AS if_register,
           match[5] AS if_op,
           match[6]::integer AS if_value
    FROM day08 AS d,
         regexp_match(d.input, '^(\w+) (\w+) (-?\d+) if (\w+) ([!=<>]+) (-?\d+)$') AS match
),
loop AS (
    SELECT 0 AS rownum,
           jsonb '{}' AS memory
    UNION ALL
    SELECT i.rownum,
           l.memory || jsonb_build_object(i.register,
               coalesce((l.memory->>i.register)::integer, 0) + i.sign * coalesce(CASE
                   WHEN i.if_op = '<=' AND coalesce((l.memory->>i.if_register)::integer, 0) <= i.if_value THEN i.diff
                   WHEN i.if_op = '<'  AND coalesce((l.memory->>i.if_register)::integer, 0) <  i.if_value THEN i.diff
                   WHEN i.if_op = '!=' AND coalesce((l.memory->>i.if_register)::integer, 0) <> i.if_value THEN i.diff
                   WHEN i.if_op = '==' AND coalesce((l.memory->>i.if_register)::integer, 0) =  i.if_value THEN i.diff
                   WHEN i.if_op = '>'  AND coalesce((l.memory->>i.if_register)::integer, 0) >  i.if_value THEN i.diff
                   WHEN i.if_op = '>=' AND coalesce((l.memory->>i.if_register)::integer, 0) >= i.if_value THEN i.diff
                   END, 0))
    FROM loop AS l
    JOIN input AS i on i.rownum = l.rownum+1
)
SELECT first_value(max_value) OVER (ORDER BY rownum DESC) AS first_star,
       max(max_value) over () AS second_star
FROM (
    SELECT rownum, max(value::text::integer) AS max_value
    FROM loop,
         jsonb_each(memory) AS e
    GROUP BY rownum
) _
ORDER BY rownum DESC
LIMIT 1;

DROP TABLE day08;
