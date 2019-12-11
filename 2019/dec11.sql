DROP TABLE IF EXISTS dec11;
CREATE TABLE dec11 (
    program text NOT NULL
);

\COPY dec11 (program) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/11/input';
VACUUM ANALYZE dec11;

/* FIRST STAR */

WITH RECURSIVE

machine (ip, relbase, output, state, x, y, dx, dy, painting, field) AS (
    SELECT 0,
           CAST(0 AS bigint),
           null::text,
           to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[])),
           0, 0, 0, -1,
           true,
           CAST('{}' AS jsonb)
    FROM dec11

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

           /* output */
           CASE WHEN opcode = 'OUT' AND painting THEN format('%s,%s,%s', x, y, arg1) END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, coalesce(field->xy, '0'))
               WHEN 'OUT'  THEN state
               WHEN 'JIT'  THEN state
               WHEN 'JIF'  THEN state
               WHEN 'LT'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END))
               WHEN 'EQ'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END))
               WHEN 'RBO'  THEN state
               WHEN 'HALT' THEN state
           ELSE
               state
           END,

           /* x */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               x + CASE arg1 WHEN '0' THEN dy ELSE -dy END
           ELSE
               x
           END,

           /* y */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               y + CASE arg1 WHEN '0' THEN -dx ELSE dx END
           ELSE
               y
           END,

           /* dx */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               CASE arg1
                   WHEN '0' THEN dy
                   WHEN '1' THEN -dy
               END
           ELSE
               dx
           END,

           /* dy */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               CASE arg1
                   WHEN '0' THEN -dx
                   WHEN '1' THEN dx
               END
           ELSE
               dy
           END,

           /* painting */
           (opcode = 'OUT') <> painting,

           /* field */
           CASE WHEN opcode = 'OUT' AND painting THEN
               jsonb_set(field, ARRAY[xy], to_jsonb(arg1), true)
           ELSE
               field
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
        END,

        /* xy */
        format('%s,%s', x, y)
    )) AS v(opcode, path1, path3, arg1, arg2, xy)

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
FROM machine
CROSS JOIN LATERAL jsonb_each(field)
WHERE state->ip = '99'
;

/* SECOND STAR */

WITH RECURSIVE

machine (ip, relbase, output, state, x, y, dx, dy, painting, field) AS (
    SELECT 0,
           CAST(0 AS bigint),
           null::text,
           to_jsonb(CAST(regexp_split_to_array(program, ',') AS bigint[])),
           0, 0, 0, -1,
           true,
           CAST('{"0,0":1}' AS jsonb)
    FROM dec11

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

           /* output */
           CASE WHEN opcode = 'OUT' AND painting THEN format('%s,%s,%s', x, y, arg1) END,

           /* state */
           CASE opcode
               WHEN 'ADD'  THEN jsonb_set(extended_state, path3, to_jsonb(arg1 + arg2))
               WHEN 'MULT' THEN jsonb_set(extended_state, path3, to_jsonb(arg1 * arg2))
               WHEN 'IN'   THEN jsonb_set(extended_state, path1, coalesce(field->xy, '0'))
               WHEN 'OUT'  THEN state
               WHEN 'JIT'  THEN state
               WHEN 'JIF'  THEN state
               WHEN 'LT'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 < arg2 THEN 1 ELSE 0 END))
               WHEN 'EQ'   THEN jsonb_set(extended_state, path3, to_jsonb(CASE WHEN arg1 = arg2 THEN 1 ELSE 0 END))
               WHEN 'RBO'  THEN state
               WHEN 'HALT' THEN state
           ELSE
               state
           END,

           /* x */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               x + CASE arg1 WHEN '0' THEN dy ELSE -dy END
           ELSE
               x
           END,

           /* y */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               y + CASE arg1 WHEN '0' THEN -dx ELSE dx END
           ELSE
               y
           END,

           /* dx */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               CASE arg1
                   WHEN '0' THEN dy
                   WHEN '1' THEN -dy
               END
           ELSE
               dx
           END,

           /* dy */
           CASE WHEN opcode = 'OUT' AND NOT painting THEN
               CASE arg1
                   WHEN '0' THEN -dx
                   WHEN '1' THEN dx
               END
           ELSE
               dy
           END,

           /* painting */
           (opcode = 'OUT') <> painting,

           /* field */
           CASE WHEN opcode = 'OUT' AND painting THEN
               jsonb_set(field, ARRAY[xy], to_jsonb(arg1), true)
           ELSE
               field
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
        END,

        /* xy */
        format('%s,%s', x, y)
    )) AS v(opcode, path1, path3, arg1, arg2, xy)

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
),

paint (x, y, value) AS (
    SELECT CAST(substring(key FOR  position(',' IN key) - 1) AS integer),
           CAST(substring(key FROM position(',' IN key) + 1) AS integer),
           CAST(value AS integer)
    FROM machine
    CROSS JOIN LATERAL jsonb_each(field)
    WHERE state->ip = '99'
),

xs (x) AS (
    SELECT min(x) FROM paint
    UNION ALL
    SELECT x + 1 FROM xs WHERE x < (SELECT max(x) FROM paint)
),

ys (y) AS (
    SELECT min(y) FROM paint
    UNION ALL
    SELECT y + 1 FROM ys WHERE y < (SELECT max(y) FROM paint)
)

SELECT string_agg(CASE WHEN p.value = 1 THEN '#' ELSE ' ' END, '' ORDER BY xs.x) AS second_star
FROM xs CROSS JOIN ys
LEFT JOIN paint AS p ON (p.x, p.y) = (xs.x, ys.y)
GROUP BY ys.y
ORDER BY ys.y
;
