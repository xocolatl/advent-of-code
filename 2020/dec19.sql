DROP TABLE IF EXISTS dec19;
CREATE TABLE dec19 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec19 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/19/input';
VACUUM ANALYZE dec19;

\timing on

/* FIRST STAR */

WITH RECURSIVE

rules (rule_number, rules) AS (
    SELECT m[1],
           string_to_array(trim(m2.m2, '"'::text), ' ')
    FROM dec19,
         LATERAL regexp_match(line, '^(\d+): (.*)$'::text) m,
         LATERAL regexp_split_to_table(m[2], ' \| '::text) m2
    WHERE m IS NOT NULL
),

messages (message) AS (
    SELECT string_to_array(line, NULL)
    FROM dec19
    WHERE line ~ '^[ab]+$'
),

t (message, rules) AS (
    SELECT message, rules
    FROM messages, rules
    WHERE rule_number = '0'

    UNION ALL

    (
    WITH input AS (TABLE t)

    SELECT t.message,
           r.rules || t.rules[2:]
    FROM input AS t
    JOIN rules AS r ON r.rule_number = t.rules[1]

    UNION ALL

    SELECT t.message[2:],
           t.rules[2:]
    FROM input AS t
    WHERE t.message[1] = t.rules[1]
      AND t.rules[1] IN ('a', 'b')
    )
)

SELECT count(*)
FROM t
WHERE message = '{}'
  AND rules = '{}'
;

/* SECOND STAR */

WITH RECURSIVE

rules (rule_number, rules) AS (
    SELECT m[1],
           string_to_array(trim(m2.m2, '"'::text), ' ')
    FROM dec19,
         LATERAL regexp_match(line, '^(\d+): (.*)$'::text) m,
         LATERAL regexp_split_to_table(m[2], ' \| '::text) m2
    WHERE m IS NOT NULL
      AND m[1] NOT IN ('8', '11')

    UNION ALL

    VALUES ('8', ARRAY['42']),
           ('8', ARRAY['42', '8']),
           ('11', ARRAY['42', '31']),
           ('11', ARRAY['42', '11', '31'])
),

messages (message) AS (
    SELECT string_to_array(line, NULL)
    FROM dec19
    WHERE line ~ '^[ab]+$'
),

t (message, rules, path, cycle) AS (
    SELECT m.message,
           r.rules,
           ARRAY[ROW(m.message, r.rules)],
           false
    FROM messages AS m
    CROSS JOIN rules AS r
    WHERE rule_number = '0'

    UNION ALL

    (
    WITH input AS (TABLE t)

    SELECT t.message,
           r.rules || t.rules[2:],
           t.path || ROW(t.message, r.rules),
           ROW(t.message, r.rules) = ANY (t.path)
    FROM input AS t
    JOIN rules AS r ON r.rule_number = t.rules[1]
    WHERE NOT t.cycle

    UNION ALL

    SELECT t.message[2:],
           t.rules[2:],
           t.path,
           t.cycle
    FROM input AS t
    WHERE t.message[1] = t.rules[1]
      AND t.rules[1] IN ('a', 'b')
      AND NOT t.cycle
    )
)

SELECT count(*)
FROM t
WHERE message = '{}'
  AND rules = '{}'
;
