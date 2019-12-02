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

-- This just brute-forces part one over all possible nouns and verbs, with an
-- arbitrary assumption that neither of them will go over 99.  That turns out
-- to be the case, but it would be nice not to hardcode it.

SELECT 100*noun + verb AS second_star
FROM generate_series(0, 99) AS noun
CROSS JOIN generate_series(0, 99) AS verb
CROSS JOIN LATERAL (
    /* This is just part one */
    WITH RECURSIVE

    machine (ip, state) AS (
        SELECT 0,
               jsonb_set(jsonb_set(to_jsonb(CAST(regexp_split_to_array(content, ',') AS integer[])),
                                   '{1}', to_jsonb(noun)),
                         '{2}', to_jsonb(verb))
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
