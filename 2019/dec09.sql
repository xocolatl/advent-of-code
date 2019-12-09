DROP TABLE IF EXISTS dec09;
CREATE TABLE dec09 (
    program text NOT NULL
);

\COPY dec09 (program) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/9/input';
VACUUM ANALYZE dec09;

/* FIRST STAR */

WITH RECURSIVE

machine (ip, relbase, inputs, outputs, state) AS (
    SELECT 0,
           CAST(0 AS bigint),
           ARRAY[1],
           CAST(ARRAY[] AS bigint[]),
           to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[]))
    FROM dec09

    UNION ALL

    SELECT /* ip */
           CASE opcode
               WHEN 'ADD'  THEN ip + 4
               WHEN 'MULT' THEN ip + 4
               WHEN 'IN'   THEN ip + 2
               WHEN 'OUT'  THEN ip + 2
               WHEN 'JIT'  THEN CASE WHEN arg1 <> 0 THEN arg2 ELSE ip + 3 END::integer
               WHEN 'JIF'  THEN CASE WHEN arg1 = 0  THEN arg2 ELSE ip + 3 END::integer
               WHEN 'LT'   THEN ip + 4
               WHEN 'EQ'   THEN ip + 4
               WHEN 'RBO'  THEN ip + 2
           ELSE
               ip
           END,

           /* relbase */
           CASE WHEN opcode = 'RBO' THEN relbase + arg1 ELSE relbase END,

           /* inputs */
           CASE WHEN opcode = 'IN'  THEN inputs[2:] ELSE inputs END,

           /* outputs */
           CASE WHEN opcode = 'OUT' THEN arg1 || outputs ELSE outputs END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, to_jsonb(inputs[1]))
               WHEN 'OUT'  THEN state
               WHEN 'JIT'  THEN state
               WHEN 'JIF'  THEN state
               WHEN 'LT'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END))
               WHEN 'EQ'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END))
               WHEN 'RBO'  THEN state
               WHEN 'HALT' THEN state
           ELSE
               '"ERROR"'
           END

    FROM machine

    /* Convenience functions */
    CROSS JOIN LATERAL (VALUES (
        /* opcode */
        CASE CAST(state->ip AS bigint) % 100
            WHEN  1 THEN 'ADD'
            WHEN  2 THEN 'MULT'
            WHEN  3 THEN 'IN'
            WHEN  4 THEN 'OUT'
            WHEN  5 THEN 'JIT'
            WHEN  6 THEN 'JIF'
            WHEN  7 THEN 'LT'
            WHEN  8 THEN 'EQ'
            WHEN  9 THEN 'RBO'
            WHEN 99 THEN 'HALT'
        ELSE CAST(CAST(state->ip AS bigint) % 100 AS text)
        END,

        /* path1 */
        CASE CAST(state->ip AS bigint) / 100 % 10
            WHEN 0 THEN ARRAY[CAST(state->(ip+1) AS text)]
            WHEN 2 THEN ARRAY[CAST(relbase + CAST(state->(ip+1) AS integer) AS text)]
        END,

        /* path3 */
        CASE CAST(state->ip AS bigint) / 10000 % 10
            WHEN 0 THEN ARRAY[CAST(state->(ip+3) AS text)]
            WHEN 2 THEN ARRAY[CAST(relbase + CAST(state->(ip+3) AS integer) AS text)]
        END,

        /* arg1 */
        CASE CAST(state->ip AS bigint) / 100 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+1) AS integer) AS bigint)
            WHEN 1 THEN CAST(state->(ip+1) AS bigint)
            WHEN 2 THEN CAST(state->(relbase::integer + CAST(state->(ip+1) AS integer)) AS bigint)
        END,

        /* arg2 */
        CASE CAST(state->ip AS bigint) / 1000 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+2) AS integer) AS bigint)
            WHEN 1 THEN CAST(state->(ip+2) AS bigint)
            WHEN 2 THEN CAST(state->(relbase::integer + CAST(state->(ip+2) AS integer)) AS bigint)
        END
    )) AS v(opcode, path1, path3, arg1, arg2)

    /* Extend the state if needed */
    CROSS JOIN LATERAL (
        WITH RECURSIVE
        gen (state, n) AS (
            VALUES (state, 0)
            UNION ALL
            SELECT state || jsonb '0', n+1
            FROM gen
            WHERE CASE WHEN opcode = 'IN' THEN
                           jsonb_array_length(state) < CAST(path1[1] AS bigint)
                       WHEN opcode IN ('ADD', 'MULT', 'LT', 'EQ') THEN
                           jsonb_array_length(state) < CAST(path3[1] AS bigint)
                  END)
        SELECT state
        FROM gen
        ORDER BY n DESC
        FETCH FIRST ROW ONLY
    ) AS v2(extended_state)

    WHERE state <> '"ERROR"'
      AND opcode <> 'HALT'
)

SELECT outputs[1] AS first_star
FROM machine
WHERE state->ip = '99'
;

/* SECOND STAR */

-- The machine is exactly the same as part one.
-- Only the initial input changes.

WITH RECURSIVE

machine (ip, relbase, inputs, outputs, state) AS (
    SELECT 0,
           CAST(0 AS bigint),
           ARRAY[2],
           CAST(ARRAY[] AS bigint[]),
           to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[]))
    FROM dec09

    UNION ALL

    SELECT /* ip */
           CASE opcode
               WHEN 'ADD'  THEN ip + 4
               WHEN 'MULT' THEN ip + 4
               WHEN 'IN'   THEN ip + 2
               WHEN 'OUT'  THEN ip + 2
               WHEN 'JIT'  THEN CASE WHEN arg1 <> 0 THEN arg2 ELSE ip + 3 END::integer
               WHEN 'JIF'  THEN CASE WHEN arg1 = 0  THEN arg2 ELSE ip + 3 END::integer
               WHEN 'LT'   THEN ip + 4
               WHEN 'EQ'   THEN ip + 4
               WHEN 'RBO'  THEN ip + 2
           ELSE
               ip
           END,

           /* relbase */
           CASE WHEN opcode = 'RBO' THEN relbase + arg1 ELSE relbase END,

           /* inputs */
           CASE WHEN opcode = 'IN'  THEN inputs[2:] ELSE inputs END,

           /* outputs */
           CASE WHEN opcode = 'OUT' THEN arg1 || outputs ELSE outputs END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, to_jsonb(inputs[1]))
               WHEN 'OUT'  THEN state
               WHEN 'JIT'  THEN state
               WHEN 'JIF'  THEN state
               WHEN 'LT'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END))
               WHEN 'EQ'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END))
               WHEN 'RBO'  THEN state
               WHEN 'HALT' THEN state
           ELSE
               '"ERROR"'
           END

    FROM machine

    /* Convenience functions */
    CROSS JOIN LATERAL (VALUES (
        /* opcode */
        CASE CAST(state->ip AS bigint) % 100
            WHEN  1 THEN 'ADD'
            WHEN  2 THEN 'MULT'
            WHEN  3 THEN 'IN'
            WHEN  4 THEN 'OUT'
            WHEN  5 THEN 'JIT'
            WHEN  6 THEN 'JIF'
            WHEN  7 THEN 'LT'
            WHEN  8 THEN 'EQ'
            WHEN  9 THEN 'RBO'
            WHEN 99 THEN 'HALT'
        ELSE CAST(CAST(state->ip AS bigint) % 100 AS text)
        END,

        /* path1 */
        CASE CAST(state->ip AS bigint) / 100 % 10
            WHEN 0 THEN ARRAY[CAST(state->(ip+1) AS text)]
            WHEN 2 THEN ARRAY[CAST(relbase + CAST(state->(ip+1) AS integer) AS text)]
        END,

        /* path3 */
        CASE CAST(state->ip AS bigint) / 10000 % 10
            WHEN 0 THEN ARRAY[CAST(state->(ip+3) AS text)]
            WHEN 2 THEN ARRAY[CAST(relbase + CAST(state->(ip+3) AS integer) AS text)]
        END,

        /* arg1 */
        CASE CAST(state->ip AS bigint) / 100 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+1) AS integer) AS bigint)
            WHEN 1 THEN CAST(state->(ip+1) AS bigint)
            WHEN 2 THEN CAST(state->(relbase::integer + CAST(state->(ip+1) AS integer)) AS bigint)
        END,

        /* arg2 */
        CASE CAST(state->ip AS bigint) / 1000 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+2) AS integer) AS bigint)
            WHEN 1 THEN CAST(state->(ip+2) AS bigint)
            WHEN 2 THEN CAST(state->(relbase::integer + CAST(state->(ip+2) AS integer)) AS bigint)
        END
    )) AS v(opcode, path1, path3, arg1, arg2)

    /* Extend the state if needed */
    CROSS JOIN LATERAL (
        WITH RECURSIVE
        gen (state, n) AS (
            VALUES (state, 0)
            UNION ALL
            SELECT state || jsonb '0', n+1
            FROM gen
            WHERE CASE WHEN opcode = 'IN' THEN
                           jsonb_array_length(state) < CAST(path1[1] AS bigint)
                       WHEN opcode IN ('ADD', 'MULT', 'LT', 'EQ') THEN
                           jsonb_array_length(state) < CAST(path3[1] AS bigint)
                  END)
        SELECT state
        FROM gen
        ORDER BY n DESC
        FETCH FIRST ROW ONLY
    ) AS v2(extended_state)

    WHERE state <> '"ERROR"'
      AND opcode <> 'HALT'
)

SELECT outputs[1] AS second_star
FROM machine
WHERE state->ip = '99'
;
