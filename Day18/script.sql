CREATE TABLE day18 (rownum serial, input text);

\COPY day18 (input) FROM 'input.txt'

WITH RECURSIVE
input (rownum, instruction, arg1, arg2) AS (
    SELECT rownum,
           match[1],
           match[2],
           match[3]
    FROM day18,
         regexp_match(input, '^(\w+) (\w)(?: (-?\d+|\w))?$') AS match
),
play (rownum, ip, instruction, arg1, arg2, note, memory) AS (
    SELECT 0::bigint,
           1::bigint,
           null::text, null::text, null::text,
           null::bigint,
           jsonb '{}'
    UNION ALL
    SELECT p.rownum+1,
           CASE i.instruction
               WHEN 'jgz' THEN
                   CASE WHEN coalesce((p.memory->>i.arg1)::bigint, 0) > 0 THEN
                       CASE WHEN i.arg2 ~ '^-?\d+$' THEN i.arg2::bigint ELSE coalesce((p.memory->>i.arg2)::bigint, 0) END
                   ELSE 1
                   END
               WHEN 'rcv' THEN
                   CASE WHEN coalesce((p.memory->>i.arg1)::bigint, 0) = 0 THEN 1 END
           ELSE 1
           END + p.ip,
           i.instruction, i.arg1, i.arg2,
           CASE WHEN i.instruction = 'snd' THEN coalesce((p.memory->>i.arg1)::bigint, 0) ELSE p.note END,
           p.memory ||
           CASE i.instruction
               WHEN 'add' THEN
                   jsonb_build_object(i.arg1, coalesce((p.memory->>i.arg1)::bigint, 0) +
                       CASE WHEN i.arg2 ~ '^-?\d+$' THEN i.arg2::bigint ELSE coalesce((p.memory->>i.arg2)::bigint, 0) END)
               WHEN 'mod' THEN
                   jsonb_build_object(i.arg1, coalesce((p.memory->>i.arg1)::bigint, 0) %
                       CASE WHEN i.arg2 ~ '^-?\d+$' THEN i.arg2::bigint ELSE coalesce((p.memory->>i.arg2)::bigint, 0) END)
               WHEN 'mul' THEN
                   jsonb_build_object(i.arg1, coalesce((p.memory->>i.arg1)::bigint, 0) *
                       CASE WHEN i.arg2 ~ '^-?\d+$' THEN i.arg2::bigint ELSE coalesce((p.memory->>i.arg2)::bigint, 0) END)
               WHEN 'set' THEN
                   jsonb_build_object(i.arg1,
                       CASE WHEN i.arg2 ~ '^-?\d+$' THEN i.arg2::bigint ELSE coalesce((p.memory->>i.arg2)::bigint, 0) END)
           ELSE
               jsonb '{}'
           END
    FROM play AS p
    JOIN input AS i ON i.rownum = p.ip
)
SELECT note AS first_star
FROM play
WHERE ip IS NULL;

DROP TABLE day18;
