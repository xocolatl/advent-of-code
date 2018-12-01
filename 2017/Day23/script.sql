CREATE TABLE day23 (rownum serial, input text);

\COPY day23 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT rownum,
           match[1] as instruction,
           match[2] as register,
           match[3] as arg
    FROM day23,
         regexp_match(input, '^(\w+) (\w) (\w|-?\d+)$') AS match
),
run AS (
    SELECT 0 AS step,
           1 AS ip,
           0 AS mul_count,
           jsonb '{}' AS memory
           , '' AS instruction, '' AS register, '' AS arg
    UNION ALL
    SELECT r.step+1,
           r.ip +
               CASE
                   WHEN i.instruction = 'jnz' AND
                        CASE WHEN i.register ~ '^-?\d+$'
                             THEN i.register::integer
                             ELSE coalesce((r.memory->>i.register)::integer, 0)
                        END <> 0
                   THEN CASE WHEN i.arg ~ '^-?\d+$'
                             THEN i.arg::integer 
                             ELSE coalesce((r.memory->>i.arg)::integer, 0)
                        END
               ELSE 1
               END,
           r.mul_count + CASE WHEN i.instruction = 'mul' THEN 1 ELSE 0 END,
           r.memory ||
               CASE i.instruction
                   WHEN 'mul' THEN 
                       jsonb_build_object(i.register,
                           CASE WHEN i.register ~ '^-?\d+$' THEN i.register::integer ELSE coalesce((r.memory->>i.register)::integer, 0) END *
                           CASE WHEN i.arg ~ '^-?\d+$' THEN i.arg::integer ELSE coalesce((r.memory->>i.arg)::integer, 0) END)
                   WHEN 'set' THEN 
                       jsonb_build_object(i.register, CASE WHEN i.arg ~ '^-?\d+$' THEN i.arg::integer ELSE coalesce((r.memory->>i.arg)::integer, 0) END)
                   WHEN 'sub' THEN 
                       jsonb_build_object(i.register,
                           CASE WHEN i.register ~ '^-?\d+$' THEN i.register::integer ELSE coalesce((r.memory->>i.register)::integer, 0) END -
                           CASE WHEN i.arg ~ '^-?\d+$' THEN i.arg::integer ELSE coalesce((r.memory->>i.arg)::integer, 0) END)
               ELSE '{}'
               END
           ,i.instruction, i.register, i.arg
    FROM run AS r
    JOIN input AS i ON i.rownum = r.ip
),
first_star AS (
    SELECT mul_count AS first_star
    FROM run
    ORDER BY step DESC
    LIMIT 1
),
second_star AS (
    /*
     * Since this problem is about optimizing by human brain, I allow myself
     * quite a bit of "cheating" here.  Otherwise I would have had to write a
     * query that optimized the assembly on its own, and that wasn't going to
     * happen.
     */
    SELECT count(nullif(EXISTS(
        SELECT
        FROM unnest('{2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,'
                    '71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,'
                    '149,151,157,163,167,173,179,181,191,193,197,199,211,'
                    '223,227,229,233,239,241,251,257,263,269,271,277,281,'
                    '283,293,307,311,313,317,331,337,347,349,353,359,367,'
                    '373,379,383,389,397,401,409,419,421,431,433,439,443,'
                    '449,457,461,463,467,479,487,491,499}'::integer[]) AS u(p)
        WHERE g % p = 0), false)) AS second_star
    FROM (SELECT 100000 + 100 * arg::integer AS value FROM input WHERE rownum = 1) AS seed,
         generate_series(seed.value, seed.value+17000, 17) AS g
)
SELECT (TABLE first_star),
       (TABLE second_star);

DROP TABLE day23;
