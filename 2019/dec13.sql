DROP TABLE IF EXISTS dec13;
CREATE TABLE dec13 (
    program text NOT NULL
);

\COPY dec13 (program) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/13/input';
VACUUM ANALYZE dec13;

/*
 * These queries work but they're kind of slow due to all the rows that are
 * generated as we execute the code.  Especially the second star, which
 * requires close to infinite tape.
 *
 * Cheat replacement queries are provided that were written after disassembling
 * the code.
 */

/* FIRST STAR (CHEAT) */
SELECT CAST((string_to_array(program, ','))[387+1] AS integer) AS first_star
FROM dec13;

/* SECOND STAR (CHEAT) */

WITH

input (state) AS MATERIALIZED (
    SELECT to_jsonb(CAST(string_to_array(program, ',') AS bigint[]))
    FROM dec13
)

SELECT sum(CAST(state->hash AS integer)) AS second_star
FROM input

CROSS JOIN LATERAL (VALUES (
    CAST(state->589 AS integer),
    CAST(state->632 AS integer),
    CAST(state->49  AS integer),
    CAST(state->60  AS integer),
    CAST(state->613 AS integer),
    CAST(state->617 AS integer),
    CAST(state->620 AS integer)
)) AS lookups (tiles, scores, width, height, b, c, size)

CROSS JOIN LATERAL (
    WITH RECURSIVE
    gen (idx) AS (VALUES (0) UNION ALL SELECT idx+1 FROM gen WHERE idx < size)
    SELECT idx, idx % width, idx / width FROM gen
) AS generator (idx, x, y)

CROSS JOIN LATERAL (VALUES (
    (((x*height+y)*b+c)%size+scores)
)) AS hash (hash)

WHERE CAST(state->(tiles + idx) AS integer) = 2
;

\quit

/* FIRST STAR */

WITH RECURSIVE

machine (iter, disasm, ip, relbase, input, output, state) AS (
    SELECT 0, '', 0,
           CAST(0 AS bigint),
           CAST(ARRAY[] AS bigint[]),
           CAST(ARRAY[] AS bigint[]),
           to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[]))
    FROM dec13

    UNION ALL

    SELECT iter+1, disasm(ip, state),/* ip */
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

           /* input */
           CASE WHEN opcode = 'IN' THEN input ELSE input END,

           /* output */
           CASE WHEN opcode = 'OUT' THEN output || arg1 ELSE output END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, to_jsonb(input[1]))
               WHEN 'OUT'  THEN state
               WHEN 'JIT'  THEN state
               WHEN 'JIF'  THEN state
               WHEN 'LT'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END))
               WHEN 'EQ'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END))
               WHEN 'RBO'  THEN state
               WHEN 'HALT' THEN state
           ELSE
               state
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
        coalesce(
        CASE CAST(state->ip AS bigint) / 100 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+1) AS integer) AS bigint)
            WHEN 1 THEN CAST(state->(ip+1) AS bigint)
            WHEN 2 THEN CAST(state->(relbase::integer + CAST(state->(ip+1) AS integer)) AS bigint)
        END,
        0),

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

SELECT count(*) AS first_star
FROM (
    SELECT output
    FROM machine
    ORDER BY iter DESC
    FETCH FIRST ROW ONLY
) AS machine
CROSS JOIN LATERAL unnest(output) WITH ORDINALITY AS u (tile, idx)
WHERE tile = 2
  AND idx % 3 = 0
;

/* SECOND STAR */

WITH RECURSIVE

machine (iter, ip, output, ball_x, paddle_x, score, relbase, state) AS (
    SELECT 0,
           0,
           CAST(ARRAY[] AS bigint[]),
           CAST(0 AS bigint),
           CAST(0 AS bigint),
           CAST(0 AS bigint),
           CAST(0 AS bigint),
           jsonb_set(to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[])), '{0}', '2')
    FROM dec13

    UNION ALL

    SELECT iter+1,
           
           /* ip */
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

           /* output */
           CASE WHEN opcode = 'OUT' THEN output || arg1
                WHEN array_length(output, 1) = 3 THEN CAST(ARRAY[] AS bigint[])
                ELSE output
           END,

           /* ball_x */
           CASE WHEN opcode = 'OUT' AND (output || arg1)[3] = 4 THEN output[1] ELSE ball_x END,

           /* paddle_x */
           CASE WHEN opcode = 'OUT' AND (output || arg1)[3] = 3 THEN output[1] ELSE paddle_x END,

           /* score */
           CASE WHEN opcode = 'OUT' AND output = CAST(ARRAY[-1, 0] AS bigint[]) THEN arg1 ELSE score END,

           /* relbase */
           CASE WHEN opcode = 'RBO' THEN relbase + arg1 ELSE relbase END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, to_jsonb(ball_x - paddle_x))
               WHEN 'OUT'  THEN state
               WHEN 'JIT'  THEN state
               WHEN 'JIF'  THEN state
               WHEN 'LT'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END))
               WHEN 'EQ'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END))
               WHEN 'RBO'  THEN state
               WHEN 'HALT' THEN state
           ELSE
               state
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
        coalesce(
        CASE CAST(state->ip AS bigint) / 100 % 10
            WHEN 0 THEN CAST(state->CAST(state->(ip+1) AS integer) AS bigint)
            WHEN 1 THEN CAST(state->(ip+1) AS bigint)
            WHEN 2 THEN CAST(state->(relbase::integer + CAST(state->(ip+1) AS integer)) AS bigint)
        END,
        0),

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

SELECT score AS second_star
FROM machine
ORDER BY iter DESC
FETCH FIRST ROW ONLY
;
