DROP TABLE IF EXISTS dec07;
CREATE TABLE dec07 (
    program text NOT NULL
);

\COPY dec07 (program) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/7/input';
VACUUM ANALYZE dec07;

/* FIRST STAR */

WITH RECURSIVE

gen04 (n) AS (VALUES (0) UNION ALL SELECT n+1 FROM gen04 WHERE n < 4),

perms (phases) as (
    SELECT array[a.n, b.n, c.n, d.n, e.n]
    FROM gen04 AS a
    JOIN gen04 AS b ON b.n NOT IN (a.n)
    JOIN gen04 AS c ON c.n NOT IN (a.n, b.n)
    JOIN gen04 AS d ON d.n NOT IN (a.n, b.n, c.n)
    JOIN gen04 AS e ON e.n NOT IN (a.n, b.n, c.n, d.n)
),

calc (phases, result) as (
    SELECT phases, 0
    FROM perms

    UNION ALL

    SELECT phases[2:], machine.output
    FROM calc
    CROSS JOIN LATERAL (
        WITH RECURSIVE

        machine (ip, inputs, outputs, state) AS (
            SELECT 0,
                   ARRAY[phases[1], result],
                   CAST(ARRAY[] AS integer[]),
                   to_jsonb(CAST(regexp_split_to_array(program, ',') AS integer[]))
            FROM dec07

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
                ELSE CAST(CAST(state->ip AS integer) % 100 AS text)
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
              AND state->ip <> '99'
        )

        SELECT CAST(outputs[1] AS integer) AS output
        FROM machine
        WHERE (state = '"ERROR"' OR state->ip = '99')
    ) AS machine
    WHERE phases <> '{}'
)

SELECT result AS first_star
FROM calc
ORDER BY result DESC
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

