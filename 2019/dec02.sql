DROP TABLE IF EXISTS dec02;
CREATE TABLE dec02 (
    content text NOT NULL
);

\COPY dec02 (content) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/2/input';

/* FIRST STAR */

WITH RECURSIVE

machine (ip, state) AS (
    SELECT 0,
           jsonb_set(jsonb_set(to_jsonb(CAST(regexp_split_to_array(content, ',') AS integer[])),
                               '{1}', '12'),
                     '{2}', '2')
    FROM dec02

    UNION ALL

    SELECT ip + 4,
           CASE state->ip
               WHEN '1'
               THEN jsonb_set(state,
                              ARRAY[CAST(state->(ip+3) AS text)],
                              to_jsonb(CAST(state->CAST(state->(ip+1) AS integer) AS integer) +
                                       CAST(state->CAST(state->(ip+2) AS integer) AS integer)
                                      )
                             )
               WHEN '2'
               THEN jsonb_set(state,
                              ARRAY[CAST(state->(ip+3) AS text)],
                              to_jsonb(CAST(state->CAST(state->(ip+1) AS integer) AS integer) *
                                       CAST(state->CAST(state->(ip+2) AS integer) AS integer)
                                      )
                             )
               WHEN '99'
               THEN state
           ELSE
               '"ERROR"'
           END
    FROM machine
    WHERE state <> '"ERROR"'
      AND state->ip <> '99'
)

SELECT state->0 AS first_star
FROM machine
WHERE state->ip = '99';

/* SECOND STAR */

-- This just brute-forces part one over all possible nouns and verbs.

WITH RECURSIVE
generator (value) AS (
    VALUES (0)
    UNION ALL
    SELECT value + 1
    FROM generator
    WHERE value <= 99
)
SELECT 100*noun.value + verb.value AS second_star
FROM generator AS noun
CROSS JOIN generator AS verb
CROSS JOIN LATERAL (
    /* This is just part one */
    WITH RECURSIVE

    machine (ip, state) AS (
        SELECT 0,
               jsonb_set(jsonb_set(to_jsonb(CAST(regexp_split_to_array(content, ',') AS integer[])),
                                   '{1}', to_jsonb(noun.value)),
                         '{2}', to_jsonb(verb.value))
        FROM dec02

        UNION ALL

        SELECT ip + 4,
               CASE state->ip
                   WHEN '1'
                   THEN jsonb_set(state,
                                  ARRAY[CAST(state->(ip+3) AS text)],
                                  to_jsonb(CAST(state->CAST(state->(ip+1) AS integer) AS integer) +
                                           CAST(state->CAST(state->(ip+2) AS integer) AS integer)
                                          )
                                 )
                   WHEN '2'
                   THEN jsonb_set(state,
                                  ARRAY[CAST(state->(ip+3) AS text)],
                                  to_jsonb(CAST(state->CAST(state->(ip+1) AS integer) AS integer) *
                                           CAST(state->CAST(state->(ip+2) AS integer) AS integer)
                                          )
                                 )
                   WHEN '99'
                   THEN state
               ELSE
                   '"ERROR"'
               END
        FROM machine
        WHERE state <> '"ERROR"'
          AND state->ip <> '99'
    )

    TABLE machine
) AS machine
WHERE state->ip = '99'
  AND state->0 = '19690720';
