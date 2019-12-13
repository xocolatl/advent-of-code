DROP TABLE IF EXISTS dec07;
CREATE TABLE dec07 (
    program text NOT NULL
);

\COPY dec07 (program) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/7/input';
VACUUM ANALYZE dec07;

/* FIRST STAR */

WITH RECURSIVE

gen04 (n) AS (VALUES (0) UNION ALL SELECT n + 1 FROM gen04 WHERE n < 4),

permutations (phases) AS (
    SELECT ARRAY[a.n, b.n, c.n, d.n, e.n]
    FROM gen04 AS a
    JOIN gen04 AS b ON b.n NOT IN (a.n)
    JOIN gen04 AS c ON c.n NOT IN (a.n, b.n)
    JOIN gen04 AS d ON d.n NOT IN (a.n, b.n, c.n)
    JOIN gen04 AS e ON e.n NOT IN (a.n, b.n, c.n, d.n)
),

calc (phases, result) AS (
    SELECT phases, 0
    FROM permutations

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
                       WHEN 'IN'   THEN jsonb_set(state, ARRAY[CAST(state->(ip + 1) AS text)], to_jsonb(inputs[1]))
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
                ARRAY[CAST(state->(ip + 3) AS text)],

                /* arg1 */
                CASE CAST(state->ip AS integer) / 100 % 10
                    WHEN 0 THEN CAST(state->CAST(state->(ip + 1) AS integer) AS integer)
                    WHEN 1 THEN CAST(state->(ip + 1) AS integer)
                END,

                /* arg2 */
                CASE CAST(state->ip AS integer) / 1000 % 10
                    WHEN 0 THEN CAST(state->CAST(state->(ip + 2) AS integer) AS integer)
                    WHEN 1 THEN CAST(state->(ip + 2) AS integer)
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

-- It took me about a week to write this query, and I ended up rewriting the
-- interpreter from scratch.  It could probably be improved but at this point
-- I'm just happy it works.

WITH RECURSIVE

gen59 (n) AS (VALUES (5) UNION ALL SELECT n + 1 FROM gen59 WHERE n < 9),

build_machines (machines) AS (
    SELECT jsonb_build_array(
                jsonb_build_object('ip', 0, 'inputs', jsonb_build_array(a.n, 0), 'state', program),
                jsonb_build_object('ip', 0, 'inputs', jsonb_build_array(b.n), 'state', program),
                jsonb_build_object('ip', 0, 'inputs', jsonb_build_array(c.n), 'state', program),
                jsonb_build_object('ip', 0, 'inputs', jsonb_build_array(d.n), 'state', program),
                jsonb_build_object('ip', 0, 'inputs', jsonb_build_array(e.n), 'state', program)
           )
    FROM gen59 AS a
    JOIN gen59 AS b ON b.n NOT IN (a.n)
    JOIN gen59 AS c ON c.n NOT IN (a.n, b.n)
    JOIN gen59 AS d ON d.n NOT IN (a.n, b.n, c.n)
    JOIN gen59 AS e ON e.n NOT IN (a.n, b.n, c.n, d.n)
    CROSS JOIN (SELECT to_jsonb(CAST(string_to_array(program, ',') AS integer[])) FROM dec07) AS dec07 (program)
),

runner (active, machines) AS (
    SELECT 0, machines FROM build_machines

    UNION ALL

    SELECT CASE WHEN (opcode = 'HALT') OR (opcode = 'IN' AND inputs->0 IS NULL)
                THEN (active + 1) % 5
                ELSE active
           END,

           jsonb_set(jsonb_set(jsonb_set(jsonb_set(machines,
                /* ip */
                ARRAY[CAST(active AS text), 'ip'],
                to_jsonb(CASE opcode
                             WHEN 'ADD'  THEN ip + 4
                             WHEN 'MULT' THEN ip + 4
                             WHEN 'IN'   THEN CASE WHEN inputs->0 IS NOT NULL THEN ip + 2 ELSE ip END
                             WHEN 'OUT'  THEN ip + 2
                             WHEN 'JIT'  THEN CASE WHEN arg1 <> 0 THEN arg2 ELSE ip + 3 END
                             WHEN 'JIF'  THEN CASE WHEN arg1 = 0 THEN arg2 ELSE ip + 3 END
                             WHEN 'LT'   THEN ip + 4
                             WHEN 'EQ'   THEN ip + 4
                             WHEN 'HALT' THEN ip
                             ELSE ip + 1
                         END)),

                /* inputs */
                ARRAY[CAST(active AS text), 'inputs'],
                CASE WHEN opcode = 'IN' THEN rest_inputs ELSE inputs END),

                /* outputs */
                ARRAY[CAST((active + 1) % 5 AS text), 'inputs'],
                CASE WHEN opcode = 'OUT' THEN next_machine_inputs || to_jsonb(arg1) ELSE next_machine_inputs END),

                /* state */
                dest,
                CASE opcode
                    WHEN 'ADD' THEN to_jsonb(arg1 + arg2)
                    WHEN 'MULT' THEN to_jsonb(arg1 * arg2)
                    WHEN 'IN' THEN coalesce(inputs->0, to_jsonb(arg1))
                    WHEN 'LT' THEN to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END)
                    WHEN 'EQ' THEN to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END)
                ELSE
                    state
                END)
    FROM runner

    /* convenience aliases */
    CROSS JOIN LATERAL (VALUES (
        CAST(machines->active->'ip' AS integer),
        machines->active->'state',
        machines->active->'inputs',
        machines->((active + 1) % 5)->'inputs'
    )) AS v1 (ip, state, inputs, next_machine_inputs)

    CROSS JOIN LATERAL (VALUES (
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
        CAST(state->ip AS integer) / 100 % 10,
        CAST(state->ip AS integer) / 1000 % 10,
        CAST(state->ip AS integer) / 10000 % 10,
        jsonb_path_query_array(inputs, '$[1 TO LAST]')
    )) AS v2 (opcode, mode1, mode2, mode3, rest_inputs)

    CROSS JOIN LATERAL (VALUES (
        CASE mode1
            WHEN 0 THEN CAST(state->CAST(state->(ip + 1) AS integer) AS integer)
            WHEN 1 THEN CAST(state->(ip + 1) AS integer)
        END,
        CASE mode2
            WHEN 0 THEN CAST(state->CAST(state->(ip + 2) AS integer) AS integer)
            WHEN 1 THEN CAST(state->(ip + 2) AS integer)
        END,
        CASE mode2
            WHEN 0 THEN CAST(state->CAST(state->(ip + 3) AS integer) AS integer)
            WHEN 1 THEN CAST(state->(ip + 3) AS integer)
        END,
        CASE
            WHEN opcode IN ('ADD', 'MULT', 'LT', 'EQ')
            THEN ARRAY[CAST(active AS text), 'state', CAST(state->(ip + 3) AS text)]

            WHEN opcode = 'IN'
            THEN ARRAY[CAST(active AS text), 'state', CAST(state->(ip + 1) AS text)]

            ELSE ARRAY[CAST(active AS text), 'state']
        END
    )) AS v3 (arg1, arg2, arg3, dest)

    /* Stop when machine E halts */
    WHERE CAST(machines->4->'state'->CAST(machines->4->'ip' AS integer) AS integer) % 100 <> 99
)

/* The result ends up in the input for (halted) machine A */
SELECT CAST(machines->0->'inputs'->0 AS integer) AS second_star
FROM runner
WHERE CAST(machines->4->'state'->CAST(machines->4->'ip' AS integer) AS integer) % 100 = 99
ORDER BY second_star DESC
FETCH FIRST ROW ONLY
;
