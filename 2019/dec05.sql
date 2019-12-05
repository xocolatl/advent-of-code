DROP TABLE IF EXISTS dec05;
CREATE TABLE dec05 (
    content text NOT NULL
);

\COPY dec05 (content) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/5/input';
VACUUM ANALYZE dec05;

/* FIRST STAR */

WITH RECURSIVE

machine (ip, inputs, outputs, state) AS (
    SELECT 0,
           ARRAY[1],
           CAST(ARRAY[] AS integer[]),
           to_jsonb(CAST(regexp_split_to_array(content, ',') AS integer[]))
    FROM dec05

    UNION ALL

    SELECT /* ip */
           CASE opcode
               WHEN 'ADD'  THEN ip + 4
               WHEN 'MULT' THEN ip + 4
               WHEN 'IN'   THEN ip + 2
               WHEN 'OUT'  THEN ip + 2
           ELSE
               ip
           END,

           /* inputs */
           CASE WHEN opcode = 'IN' THEN inputs[2:] ELSE inputs END,

           /* outputs */
           CASE WHEN opcode = 'OUT' THEN arg1 || outputs ELSE outputs END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(state, path, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(state, path, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(state, ARRAY[CAST(state->(ip+1) AS text)], to_jsonb(inputs[1]))
               WHEN 'OUT'  THEN state
               WHEN 'HALT' THEN state
           ELSE
               '"ERROR"'
           END

    FROM machine
    CROSS JOIN LATERAL (VALUES (
        /* opcode */
        CASE CAST(state->ip AS integer) % 100
            WHEN  1 THEN 'ADD'
            WHEN  2 THEN 'MULT'
            WHEN  3 THEN 'IN'
            WHEN  4 THEN 'OUT'
            WHEN 99 THEN 'HALT'
        ELSE (CAST(state->ip AS integer) % 100)::text
        END,

        /* path */
        ARRAY[CAST(state->(ip+3) AS text)],

        /* arg1 */
        CASE CAST(state->ip AS integer) / 100 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+1) AS integer) AS integer)
            WHEN 1 THEN CAST(state->(ip+1) AS integer)
        END,

        /* arg2 */
        CASE CAST(state->ip AS integer) / 1000 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+2) AS integer) AS integer)
            WHEN 1 THEN CAST(state->(ip+2) AS integer)
        END
    )) AS v(opcode, path, arg1, arg2)
    WHERE state <> '"ERROR"'
      AND opcode <> 'HALT'
)

SELECT outputs[1] AS first_star
FROM machine
WHERE outputs[1] <> 0
  AND outputs[2:] <@ ARRAY[0]
;

/* SECOND STAR */

WITH RECURSIVE

machine (ip, inputs, outputs, state) AS (
    SELECT 0,
           ARRAY[5],
           CAST(ARRAY[] AS integer[]),
           to_jsonb(CAST(regexp_split_to_array(content, ',') AS integer[]))
    FROM dec05

    UNION ALL

    SELECT /* ip */
           CASE opcode
               WHEN 'ADD'  THEN ip + 4
               WHEN 'MULT' THEN ip + 4
               WHEN 'IN'   THEN ip + 2
               WHEN 'OUT'  THEN ip + 2
               WHEN 'JIT'  THEN CASE WHEN arg1 <> 0 THEN arg2 ELSE ip + 3 END
               WHEN 'JIF'  THEN CASE WHEN arg1 = 0  THEN arg2 ELSE ip + 3 END
               WHEN 'LT'   THEN ip + 4
               WHEN 'EQ'   THEN ip + 4
           ELSE
               ip
           END,

           /* inputs */
           CASE WHEN opcode = 'IN' THEN inputs[2:] ELSE inputs END,

           /* outputs */
           CASE WHEN opcode = 'OUT' THEN arg1 || outputs ELSE outputs END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(state, path, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(state, path, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(state, ARRAY[CAST(state->(ip+1) AS text)], to_jsonb(inputs[1]))
               WHEN 'OUT'  THEN state
               WHEN 'JIT'  THEN state
               WHEN 'JIF'  THEN state
               WHEN 'LT'   THEN jsonb_set(state, path, to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END))
               WHEN 'EQ'   THEN jsonb_set(state, path, to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END))
               WHEN 'HALT' THEN state
           ELSE
               '"ERROR"'
           END

    FROM machine
    CROSS JOIN LATERAL (VALUES (
        /* opcode */
        CASE CAST(state->ip AS integer) % 100
            WHEN  1 THEN 'ADD'
            WHEN  2 THEN 'MULT'
            WHEN  3 THEN 'IN'
            WHEN  4 THEN 'OUT'
            WHEN  5 THEN 'JIT'
            WHEN  6 THEN 'JIF'
            WHEN  7 THEN 'LT'
            WHEN  8 THEN 'EQ'
            WHEN 99 THEN 'HALT'
        ELSE (CAST(state->ip AS integer) % 100)::text
        END,

        /* path */
        ARRAY[CAST(state->(ip+3) AS text)],

        /* arg1 */
        CASE CAST(state->ip AS integer) / 100 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+1) AS integer) AS integer)
            WHEN 1 THEN CAST(state->(ip+1) AS integer)
        END,

        /* arg2 */
        CASE CAST(state->ip AS integer) / 1000 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+2) AS integer) AS integer)
            WHEN 1 THEN CAST(state->(ip+2) AS integer)
        END
    )) AS v(opcode, path, arg1, arg2)
    WHERE state <> '"ERROR"'
      AND opcode <> 'HALT'
)

SELECT outputs[1] AS second_star
FROM machine
WHERE outputs <> '{}'
;
