CREATE TABLE day10 (rownum serial, input text);

\COPY day10 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT ARRAY(SELECT generate_series(0, 255)) AS list,
           string_to_array(input, ',')::integer[] AS lengths
    FROM day10
),
loop AS (
    SELECT list,
           lengths,
           0 AS position,
           0 AS step_size,
           array_length(list, 1) AS len
    FROM input
    UNION ALL
    SELECT rotated_list[len-position+1:] || rotated_list[:len-position] AS list,
           lengths[2:],
           (position + lengths[1] + step_size) % len,
           step_size+1,
           len
    FROM (
        SELECT ARRAY(SELECT n
                     FROM unnest(rotated_list[:lengths[1]]) WITH ORDINALITY AS u(n,o)
                     ORDER BY o DESC) || rotated_list[lengths[1]+1:] AS rotated_list,
               lengths, position, step_size, len
        FROM (
            SELECT list[position+1:] || list[:position] AS rotated_list,
                   lengths, position, step_size, len
            FROM loop
            WHERE lengths <> '{}'
        ) _
    ) _
)
SELECT list[1] * list[2] AS first_star
FROM loop
ORDER BY step_size DESC
LIMIT 1;

/* Part II needs a custom aggregate */

CREATE AGGREGATE xor_agg(integer) (
    SFUNC = int4xor,
    STYPE = integer
);

WITH RECURSIVE
input AS (
    SELECT ARRAY(SELECT generate_series(0, 255)) AS list,
           ARRAY(SELECT n
                 FROM unnest(ARRAY(
                         SELECT ascii(n)
                         FROM unnest(string_to_array((SELECT input FROM day10), null)::character[]) WITH ORDINALITY AS u(n, o)
                         ORDER BY o) || ARRAY[17, 31, 73, 47, 23]
                      ) WITH ORDINALITY u(n, o),
                      generate_series(1, 64) AS g
                 ORDER BY g, o) AS lengths
),
loop AS ( /* This is exactly the same as for the first star */
    SELECT list,
           lengths,
           0 AS position,
           0 AS step_size,
           array_length(list, 1) AS len
    FROM input
    UNION ALL
    SELECT rotated_list[len-position+1:] || rotated_list[:len-position] AS list,
           lengths[2:],
           (position + lengths[1] + step_size) % len,
           step_size+1,
           len
    FROM (
        SELECT ARRAY(SELECT n
                     FROM unnest(rotated_list[:lengths[1]]) WITH ORDINALITY AS u(n,o)
                     ORDER BY o DESC) || rotated_list[lengths[1]+1:] AS rotated_list,
               lengths, position, step_size, len
        FROM (
            SELECT list[position+1:] || list[:position] AS rotated_list,
                   lengths, position, step_size, len
            FROM loop
            WHERE lengths <> '{}'
        ) _
    ) _
)
SELECT string_agg(lpad(to_hex(val), 2, '0'), '' ORDER BY pos) AS second_star
FROM (
    SELECT xor_agg(val) AS val, (pos-1)/16 AS pos
    FROM unnest((SELECT list FROM loop ORDER BY step_size DESC LIMIT 1))
            WITH ORDINALITY AS u(val, pos)
    GROUP BY (pos-1)/16
) _;

DROP AGGREGATE xor_agg(integer);
DROP TABLE day10;
