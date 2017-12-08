CREATE TABLE day08 (rownum serial, input text);

\COPY day08 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
SELECT d.rownum,
       match[1] AS register,
       match[2] AS op,
       match[3]::integer AS diff,
       match[4] AS if_register,
       match[5] AS if_op,
       match[6]::integer AS if_value
FROM day08 AS d,
     regexp_match(d.input, '^(\w+) (\w+) (-?\d+) if (\w+) ([!=<>]+) (-?\d+)$') AS match
),

loop (rownum, register, op, diff, if_register, if_op, if_value, memory) AS (
    SELECT 0,
           null::text,
           null::text,
           null::integer,
           null::text,
           null::text,
           null::integer,
           jsonb '{}'
    UNION ALL
    SELECT i.rownum,
           i.register,
           i.op,
           i.diff,
           i.if_register,
           i.if_op,
           i.if_value,
           l.memory || jsonb_build_object(i.register,
               CASE i.if_op
                   WHEN '<=' THEN
                       CASE WHEN coalesce((l.memory->>i.if_register)::integer, 0) <= i.if_value THEN
                           CASE i.op WHEN 'inc' THEN coalesce((l.memory->>i.register)::integer, 0) + i.diff
                                     WHEN 'dec' THEN coalesce((l.memory->>i.register)::integer, 0) - i.diff
                           END
                       ELSE coalesce((l.memory->>i.register)::integer, 0)
                       END
                   WHEN '<' THEN
                       CASE WHEN coalesce((l.memory->>i.if_register)::integer, 0) < i.if_value THEN
                           CASE i.op WHEN 'inc' THEN coalesce((l.memory->>i.register)::integer, 0) + i.diff
                                     WHEN 'dec' THEN coalesce((l.memory->>i.register)::integer, 0) - i.diff
                           END
                       ELSE coalesce((l.memory->>i.register)::integer, 0)
                       END
                   WHEN '!=' THEN
                       CASE WHEN coalesce((l.memory->>i.if_register)::integer, 0) <> i.if_value THEN
                           CASE i.op WHEN 'inc' THEN coalesce((l.memory->>i.register)::integer, 0) + i.diff
                                     WHEN 'dec' THEN coalesce((l.memory->>i.register)::integer, 0) - i.diff
                           END
                       ELSE coalesce((l.memory->>i.register)::integer, 0)
                       END
                   WHEN '==' THEN
                       CASE WHEN coalesce((l.memory->>i.if_register)::integer, 0) = i.if_value THEN
                           CASE i.op WHEN 'inc' THEN coalesce((l.memory->>i.register)::integer, 0) + i.diff
                                     WHEN 'dec' THEN coalesce((l.memory->>i.register)::integer, 0) - i.diff
                           END
                       ELSE coalesce((l.memory->>i.register)::integer, 0)
                       END
                   WHEN '>' THEN
                       CASE WHEN coalesce((l.memory->>i.if_register)::integer, 0) > i.if_value THEN
                           CASE i.op WHEN 'inc' THEN coalesce((l.memory->>i.register)::integer, 0) + i.diff
                                     WHEN 'dec' THEN coalesce((l.memory->>i.register)::integer, 0) - i.diff
                           END
                       ELSE coalesce((l.memory->>i.register)::integer, 0)
                       END
                   WHEN '>=' THEN
                       CASE WHEN coalesce((l.memory->>i.if_register)::integer, 0) >= i.if_value THEN
                           CASE i.op WHEN 'inc' THEN coalesce((l.memory->>i.register)::integer, 0) + i.diff
                                     WHEN 'dec' THEN coalesce((l.memory->>i.register)::integer, 0) - i.diff
                           END
                       ELSE coalesce((l.memory->>i.register)::integer, 0)
                       END
               END)
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
