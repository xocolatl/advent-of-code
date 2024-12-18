CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec17;

CREATE TABLE dec17 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec17 (line) FROM '2024/dec17.input' NULL ''
VACUUM ANALYZE dec17;

/**************/
/* FIRST STAR */
/**************/

WITH RECURSIVE

input (rega, regb, regc, program) AS (
    VALUES ((SELECT CAST((regexp_match(line, 'Register A: (\d+)'))[1] AS INTEGER) FROM dec17 WHERE line_number = 1),
            (SELECT CAST((regexp_match(line, 'Register B: (\d+)'))[1] AS INTEGER) FROM dec17 WHERE line_number = 2),
            (SELECT CAST((regexp_match(line, 'Register C: (\d+)'))[1] AS INTEGER) FROM dec17 WHERE line_number = 3),
            (SELECT CAST(string_to_array((regexp_match(line, 'Program: ((\d+,?)+)'))[1], ',') AS INTEGER ARRAY) FROM dec17 WHERE line_number = 5))
),

run (ip, rega, regb, regc, program, out) AS (
    SELECT 1, rega, regb, regc, program, CAST(ARRAY[] AS INTEGER ARRAY)
    FROM input

    UNION ALL

    SELECT /* ip */
           CASE WHEN program[ip] = 3 AND rega > 0 /* jnz */
                THEN program[ip+1] + 1
                ELSE ip + 2
           END,

           /* register A */
           CASE program[ip]
                WHEN 0 /* adv */
                THEN CAST(trunc(rega / POWER(2, combos[program[ip+1]+1])) AS INTEGER)
                ELSE rega
           END,

           /* register B */
           CASE program[ip]
                WHEN 1 /* bxl */
                THEN regb # program[ip+1]

                WHEN 2 /* bst */
                THEN MOD(combos[program[ip+1]+1], 8)

                WHEN 4 /* bxc */
                THEN regb # regc

                WHEN 6 /* bdv */
                THEN CAST(trunc(rega / POWER(2, combos[program[ip+1]+1])) AS INTEGER)

                ELSE regb
           END,

           /* register C */
           CASE program[ip]
                WHEN 7 /* cdv */
                THEN CAST(trunc(rega / POWER(2, combos[program[ip+1]+1])) AS INTEGER)
                ELSE regc
           END,

           program,

           /* output */
           CASE WHEN program[ip] = 5 /* out */
                THEN out || MOD(combos[program[ip+1]+1], 8)
                ELSE out
           END
    FROM run
    CROSS JOIN LATERAL (VALUES (ARRAY[0, 1, 2, 3, rega, regb, regc, NULL])) AS combos (combos)
    WHERE program[ip] IS NOT NULL
)

SELECT array_to_string(out, ',') AS first_star
FROM run
WHERE program[ip] IS NULL
;

/***************/
/* SECOND STAR */
/***************/

WITH RECURSIVE

input (rega, regb, regc, program) AS (
    VALUES ((SELECT CAST((regexp_match(line, 'Register A: (\d+)'))[1] AS BIGINT) FROM dec17 WHERE line_number = 1),
            (SELECT CAST((regexp_match(line, 'Register B: (\d+)'))[1] AS BIGINT) FROM dec17 WHERE line_number = 2),
            (SELECT CAST((regexp_match(line, 'Register C: (\d+)'))[1] AS BIGINT) FROM dec17 WHERE line_number = 3),
            (SELECT CAST(string_to_array((regexp_match(line, 'Program: ((\d+,?)+)'))[1], ',') AS BIGINT ARRAY) FROM dec17 WHERE line_number = 5))
),

loop (seed, idx, out) AS (
    SELECT CAST(0 AS BIGINT),
           CARDINALITY(program),
           '{}'::BIGINT[]
    FROM input

    UNION ALL

    SELECT 8 * seed + g,
           idx - 1,
           r.out
    FROM loop
    CROSS JOIN generate_series(0, 7) AS g
    JOIN LATERAL (
        WITH RECURSIVE
        run (ip, rega, regb, regc, program, out) AS (
            SELECT CAST(1 AS BIGINT), 8*seed+g, regb, regc, program, CAST(ARRAY[] AS BIGINT ARRAY)
            FROM input
        
            UNION ALL
        
            SELECT /* ip */
                   CASE WHEN NOT program @> out THEN NULL
                        WHEN program[ip] = 3 AND rega > 0 /* jnz */
                        THEN program[ip+1] + 1
                        ELSE ip + 2
                   END,
        
                   /* register A */
                   CASE program[ip]
                        WHEN 0 /* adv */
                        THEN CAST(trunc(rega / POWER(2, combos[program[ip+1]+1])) AS BIGINT)
                        ELSE rega
                   END,
        
                   /* register B */
                   CASE program[ip]
                        WHEN 1 /* bxl */
                        THEN regb # program[ip+1]
        
                        WHEN 2 /* bst */
                        THEN MOD(combos[program[ip+1]+1], 8)
        
                        WHEN 4 /* bxc */
                        THEN regb # regc
        
                        WHEN 6 /* bdv */
                        THEN CAST(trunc(rega / POWER(2, combos[program[ip+1]+1])) AS BIGINT)
        
                        ELSE regb
                   END,
        
                   /* register C */
                   CASE program[ip]
                        WHEN 7 /* cdv */
                        THEN CAST(trunc(rega / POWER(2, combos[program[ip+1]+1])) AS BIGINT)
                        ELSE regc
                   END,
        
                   program,
        
                   /* output */
                   CASE WHEN program[ip] = 5 /* out */
                        THEN out || MOD(combos[program[ip+1]+1], 8)
                        ELSE out
                   END
            FROM run
            CROSS JOIN LATERAL (VALUES (ARRAY[0, 1, 2, 3, rega, regb, regc, NULL])) AS combos (combos)
            WHERE program[ip] IS NOT NULL
        )
        
        SELECT out, program
        FROM run
        WHERE program[ip] IS NULL
    ) AS r ON r.out = program[idx:]
    WHERE idx > 0
)

SELECT seed AS second_star
FROM loop
ORDER BY idx, seed
FETCH FIRST ROW ONLY
;
