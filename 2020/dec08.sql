DROP TABLE IF EXISTS dec08;
CREATE TABLE dec08 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec08 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/8/input';
VACUUM ANALYZE dec08;

\timing on

/* FIRST STAR */

WITH RECURSIVE

input (addr, opcode, arg) AS (
    SELECT line_number, m[1], CAST(m[2] AS integer)
    FROM dec08,
         LATERAL regexp_split_to_array(line, ' ') AS m
),

machine (depth, ip, accumulator, path, cycle) AS (
    VALUES (0, 1, 0, CAST(ARRAY[1] AS integer[]), false)

    UNION ALL

    SELECT m.depth + 1,
           v.ip,
           v.accumulator,
           m.path || v.ip,
           v.ip = ANY (m.path)
    FROM machine AS m
    JOIN input AS i ON i.addr = m.ip
    CROSS JOIN LATERAL (VALUES (
        m.ip + CASE WHEN opcode = 'jmp' THEN arg ELSE 1 END,
        m.accumulator + CASE WHEN opcode = 'acc' THEN arg ELSE 0 END
    )) AS v (ip, accumulator)
    WHERE NOT cycle
)

SELECT accumulator
FROM machine
WHERE NOT cycle
ORDER BY depth DESC
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

WITH RECURSIVE

input (addr, opcode, arg) AS (
    SELECT line_number, m[1], CAST(m[2] AS integer)
    FROM dec08,
         LATERAL regexp_split_to_array(line, ' ') AS m
),

machines (id) AS (
    SELECT addr
    FROM input
    WHERE opcode IN ('jmp', 'nop')
),

machine (id, depth, ip, accumulator, path, cycle) AS (
    SELECT id, 0, 1, 0, ARRAY[1], false
    FROM machines

    UNION ALL

    SELECT m.id,
           m.depth + 1,
           v.ip,
           v.accumulator,
           m.path || v.ip,
           v.ip = ANY (m.path)
    FROM machine AS m
    JOIN input AS i ON i.addr = m.ip
    CROSS JOIN LATERAL (VALUES (
        CASE WHEN m.id = m.ip
             THEN CASE WHEN i.opcode = 'jmp' THEN 'nop'
                       WHEN i.opcode = 'nop' THEN 'jmp'
                  END
             ELSE i.opcode
        END
    )) AS flip (opcode)
    CROSS JOIN LATERAL (VALUES (
        m.ip + CASE WHEN flip.opcode = 'jmp' THEN arg ELSE 1 END,
        m.accumulator + CASE WHEN flip.opcode = 'acc' THEN arg ELSE 0 END
    )) AS v (ip, accumulator)
    WHERE NOT cycle
),

results (depth, accumulator, no_cycle) AS (
    SELECT depth,
           accumulator,
           every(NOT cycle) OVER w
    FROM machine
    WINDOW w AS (PARTITION BY id)
)

SELECT accumulator
FROM results
WHERE no_cycle
ORDER BY depth DESC
FETCH FIRST ROW ONLY
;
