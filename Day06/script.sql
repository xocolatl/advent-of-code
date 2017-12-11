CREATE TABLE day06 (rownum serial, input text);

/* The delimiter is just something other than TAB */
\COPY day06 (input) FROM 'input.txt' (DELIMITER ';')

/*
 * PostgreSQL is not very good at arrays of arrays, so `seen` tracks the
 * textual representation.  Eww.
 */

WITH RECURSIVE
awale AS (
    SELECT 1 AS steps,
           string_to_array(input, E'\t')::integer[] AS current,
           array[string_to_array(input, E'\t')::integer[]::text] AS seen,
           false AS stop,
           0 AS val,
           0 AS pos
    FROM day06
    UNION ALL
    SELECT awale.steps+1,
           redistributed,
           awale.seen || redistributed::text,
           awale.seen @> array[redistributed::text],
           valpos.val,
           valpos.pos
    FROM awale,
    LATERAL (SELECT u.val,
                    u.pos::integer,
                    array_length(awale.current, 1) AS len
             FROM unnest(awale.current) WITH ORDINALITY u(val, pos)
             ORDER BY u.val DESC, u.pos ASC
             LIMIT 1) AS valpos,
    LATERAL (SELECT array_agg(CASE WHEN u.pos = valpos.pos THEN 0 ELSE u.val END
                              + (valpos.val / valpos.len)
                              + CASE WHEN (u.pos + valpos.len - valpos.pos - 1) % valpos.len < valpos.val % valpos.len THEN 1 ELSE 0 END
                              ORDER BY u.pos) AS redistributed
             FROM unnest(current) WITH ORDINALITY u(val, pos)) AS redistributed
    WHERE NOT awale.stop
)
SELECT awale.steps - 1 AS first_star,
       array_length(awale.seen, 1) - array_position(awale.seen, awale.current::text) AS second_star
FROM awale
WHERE awale.stop;

DROP TABLE day06;
