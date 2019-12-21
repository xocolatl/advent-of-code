DROP TABLE IF EXISTS dec21;
CREATE TABLE dec21 (
    program text NOT NULL
);

\COPY dec21 (program) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/21/input';
VACUUM ANALYZE dec21;

-- The machines are identical in both parts.

/* FIRST STAR */

WITH RECURSIVE

machine (iter, ip, relbase, input, outputs, state) AS (
    SELECT 0,
           0,
           CAST(0 AS bigint),
           E'NOT A J
             NOT J J
             AND B J
             AND C J
             NOT J J
             AND D J
             WALK\n',
           CAST(ARRAY[] AS integer[]),
           to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[]))
    FROM dec21

    UNION ALL

    SELECT iter+1,

           /* ip */
           CASE opcode
               WHEN 'ADD'  THEN ip + 4
               WHEN 'MULT' THEN ip + 4
               WHEN 'IN'   THEN ip + 2
               WHEN 'OUT'  THEN ip + 2
               WHEN 'JIT'  THEN CASE WHEN arg1 <> 0 THEN CAST(arg2 AS integer) ELSE ip + 3 END
               WHEN 'JIF'  THEN CASE WHEN arg1 = 0  THEN CAST(arg2 AS integer) ELSE ip + 3 END
               WHEN 'LT'   THEN ip + 4
               WHEN 'EQ'   THEN ip + 4
               WHEN 'RBO'  THEN ip + 2
           ELSE
               ip
           END,

           /* relbase */
           CASE WHEN opcode = 'RBO' THEN relbase + arg1 ELSE relbase END,

           /* input */
           CASE WHEN opcode = 'IN'  THEN SUBSTRING(input FROM 2) ELSE input END,

           /* outputs */
           CASE WHEN opcode = 'OUT' THEN outputs || CAST(arg1 AS integer) ELSE outputs END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, to_jsonb(ascii(SUBSTRING(input FOR 1))))
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
            WHEN 0 THEN COALESCE(CAST(state->CAST(state->(ip+1) AS integer) AS bigint), 0)
            WHEN 1 THEN CAST(state->(ip+1) AS bigint)
            WHEN 2 THEN COALESCE(CAST(state->CAST(relbase + CAST(state->(ip+1) AS integer) AS integer) AS bigint), 0)
        END,

        /* arg2 */
        CASE CAST(state->ip AS bigint) / 1000 % 10
            WHEN 0 THEN COALESCE(CAST(state->CAST(state->(ip+2) AS integer) AS bigint), 0)
            WHEN 1 THEN CAST(state->(ip+2) AS bigint)
            WHEN 2 THEN COALESCE(CAST(state->CAST(relbase + CAST(state->(ip+2) AS integer) AS integer) AS bigint), 0)
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

SELECT outputs[array_length(outputs, 1)] AS first_star
FROM machine
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

WITH RECURSIVE

machine (iter, ip, relbase, input, outputs, state) AS (
    SELECT 0,
           0,
           CAST(0 AS bigint),
           E'NOT H J
             OR  C J
             AND B J
             AND A J
             NOT J J
             AND D J
             RUN\n',
           CAST(ARRAY[] AS integer[]),
           to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[]))
    FROM dec21

    UNION ALL

    SELECT iter+1,

           /* ip */
           CASE opcode
               WHEN 'ADD'  THEN ip + 4
               WHEN 'MULT' THEN ip + 4
               WHEN 'IN'   THEN ip + 2
               WHEN 'OUT'  THEN ip + 2
               WHEN 'JIT'  THEN CASE WHEN arg1 <> 0 THEN CAST(arg2 AS integer) ELSE ip + 3 END
               WHEN 'JIF'  THEN CASE WHEN arg1 = 0  THEN CAST(arg2 AS integer) ELSE ip + 3 END
               WHEN 'LT'   THEN ip + 4
               WHEN 'EQ'   THEN ip + 4
               WHEN 'RBO'  THEN ip + 2
           ELSE
               ip
           END,

           /* relbase */
           CASE WHEN opcode = 'RBO' THEN relbase + arg1 ELSE relbase END,

           /* input */
           CASE WHEN opcode = 'IN'  THEN SUBSTRING(input FROM 2) ELSE input END,

           /* outputs */
           CASE WHEN opcode = 'OUT' THEN outputs || CAST(arg1 AS integer) ELSE outputs END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, to_jsonb(ascii(SUBSTRING(input FOR 1))))
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
            WHEN 0 THEN COALESCE(CAST(state->CAST(state->(ip+1) AS integer) AS bigint), 0)
            WHEN 1 THEN CAST(state->(ip+1) AS bigint)
            WHEN 2 THEN COALESCE(CAST(state->CAST(relbase + CAST(state->(ip+1) AS integer) AS integer) AS bigint), 0)
        END,

        /* arg2 */
        CASE CAST(state->ip AS bigint) / 1000 % 10
            WHEN 0 THEN COALESCE(CAST(state->CAST(state->(ip+2) AS integer) AS bigint), 0)
            WHEN 1 THEN CAST(state->(ip+2) AS bigint)
            WHEN 2 THEN COALESCE(CAST(state->CAST(relbase + CAST(state->(ip+2) AS integer) AS integer) AS bigint), 0)
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

SELECT outputs[array_length(outputs, 1)] AS second_star
FROM machine
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;
