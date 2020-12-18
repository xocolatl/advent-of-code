DROP TABLE IF EXISTS dec18;
CREATE TABLE dec18 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec18 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/18/input';
VACUUM ANALYZE dec18;

\timing on

/* FIRST STAR */

WITH RECURSIVE

exec (expr, numstack, opstack) AS (
    SELECT string_to_array(translate(line, ' ', ''), NULL),
           CAST(ARRAY[] AS bigint[]),
           CAST(ARRAY[] AS text[])
    FROM dec18

    UNION ALL

    SELECT /* expr */
           CASE
           WHEN c = ')' THEN
                ARRAY[CAST(numstack[1] AS text)] || expr[2:]
           ELSE
                expr[2:]
           END,

           /* numstack */
           CASE
           WHEN c = ')' THEN
                numstack[2:]
           WHEN c ~ '\d' THEN
                CASE
                WHEN opstack[1] IS NULL OR opstack[1] = '(' THEN
                    ARRAY[CAST(c AS bigint)] || numstack
                ELSE
                    CASE opstack[1]
                        WHEN '+' THEN ARRAY[CAST(c AS bigint) + numstack[1]] || numstack[2:]
                        WHEN '*' THEN ARRAY[CAST(c AS bigint) * numstack[1]] || numstack[2:]
                        ELSE numstack
                    END
                END
           ELSE
               numstack
           END,

           /* opstack */
           CASE
           WHEN c IN ('+', '*', '(') THEN
                ARRAY[c] || opstack
           WHEN c = ')' THEN
                opstack[2:]
           ELSE
                CASE WHEN opstack[1] IN ('+', '*') THEN opstack[2:] ELSE opstack END
           END

    FROM exec
    CROSS JOIN LATERAL (VALUES (expr[1])) AS v (c)
    WHERE expr <> '{}'
)

SELECT sum(numstack[1])
FROM exec
WHERE expr = '{}'
;

/* SECOND STAR */

WITH RECURSIVE

convert (infix, stack, postfix) AS (
    SELECT string_to_array(translate(line, ' ', ''), NULL),
           CAST(ARRAY[] AS text[]),
           CAST(ARRAY[] AS text[])
    FROM dec18

    UNION ALL

    SELECT infix[2:],
           CAST(v2.so[1] AS text[]),
           CAST(v2.so[2] AS text[])
    FROM convert AS c
    CROSS JOIN LATERAL (VALUES (infix[1])) AS v (c)
    CROSS JOIN LATERAL (VALUES (
        CASE WHEN infix = '{}' THEN
                ARRAY[CAST(stack[2:] AS text),
                      CAST(postfix || stack[1] AS text)]

             WHEN c ~ '\d' THEN
                ARRAY[CAST(stack AS text),
                      CAST(postfix || ARRAY[c] AS text)]

             WHEN c = '(' THEN
                ARRAY[CAST(ARRAY[c] || stack AS text),
                      CAST(postfix AS text)]

             ELSE
                (WITH RECURSIVE
                 runner (iter, s, p) AS (
                    VALUES (0, stack, postfix)
                    UNION ALL
                    SELECT iter+1, s[2:], CASE WHEN s[1] <> '(' OR c <> ')' THEN p || s[1] ELSE p END
                    FROM runner
                    WHERE s <> '{}'
                      AND s[1] <> '('
                      AND (s[1] <> '*' OR c <> '+')
                 )
                 SELECT ARRAY[CAST(CASE WHEN c = ')' THEN s[2:] ELSE ARRAY[c] || s END AS text), CAST(p AS text)]
                 FROM runner
                 ORDER BY iter DESC
                 FETCH FIRST ROW ONLY)

        END
    )) AS v2 (so)
    WHERE (infix <> '{}' OR stack <> '{}')
),

eval (expr, stack) AS (
    SELECT postfix,
           CAST(ARRAY[] AS bigint[])
    FROM convert
    WHERE infix = '{}' and stack = '{}'

    UNION ALL

    SELECT expr[2:],
           CASE WHEN expr[1] ~ '\d' THEN ARRAY[CAST(expr[1] AS bigint)] || stack
                WHEN expr[1] = '+' THEN ARRAY[stack[1] + stack[2]] || stack[3:]
                WHEN expr[1] = '*' THEN ARRAY[stack[1] * stack[2]] || stack[3:]
           END
    FROM eval
    WHERE expr <> '{}'
)

SELECT sum(stack[1])
FROM eval
WHERE expr = '{}'
;
