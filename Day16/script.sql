CREATE TABLE day16 (rownum serial, input text);

\COPY day16 (input) FROM 'input.txt'

/* This takes about seven minutes! */

WITH RECURSIVE
input AS (
SELECT lines.ordinality AS line_number,
       match[1] AS instruction,
       match[2] AS arg1,
       match[3] AS arg2
FROM day16 AS d,
     regexp_split_to_table(d.input, ',') WITH ORDINALITY AS lines(line, ordinality),
     regexp_match(lines.line, '^([sxp])(\w+)(?:/(\w+))?$') AS match
),
wolves AS (
    SELECT 0::bigint AS line_number, 'abcdefghijklmnop' AS programs
    UNION ALL
    SELECT w.line_number+1, d.programs
    FROM wolves AS w,
         LATERAL (WITH RECURSIVE
                  dance AS (
                      SELECT 0::bigint AS line_number, string_to_array(w.programs, null)::bpchar[] AS programs
                      UNION ALL
                      SELECT i.line_number,
                             CASE i.instruction
                                 WHEN 's' THEN
                                     programs[16-i.arg1::integer+1 :] || programs[: 16-i.arg1::integer]
                                 WHEN 'x' THEN
                                     programs[:least(i.arg1::integer, i.arg2::integer)]
                                         || programs[greatest(i.arg1::integer, i.arg2::integer)+1]
                                         || programs[least(i.arg1::integer, i.arg2::integer)+2 : greatest(i.arg1::integer, i.arg2::integer)]
                                         || programs[least(i.arg1::integer, i.arg2::integer)+1]
                                         || programs[greatest(i.arg1::integer, i.arg2::integer)+2:]
                                 WHEN 'p' THEN
                                     programs[:least(array_position(programs, arg1::bpchar), array_position(programs, arg2::bpchar))-1]
                                         || programs[greatest(array_position(programs, arg1::bpchar), array_position(programs, arg2::bpchar))]
                                         || programs[least(array_position(programs, arg1::bpchar), array_position(programs, arg2::bpchar))+1
                                                   : greatest(array_position(programs, arg1::bpchar), array_position(programs, arg2::bpchar))-1]
                                         || programs[least(array_position(programs, arg1::bpchar), array_position(programs, arg2::bpchar))]
                                         || programs[greatest(array_position(programs, arg1::bpchar), array_position(programs, arg2::bpchar))+1:]
                             END
                      FROM dance AS d
                      JOIN input AS i ON i.line_number = d.line_number + 1
                   )
                   SELECT array_to_string(programs, '') AS programs
                   FROM dance
                   ORDER BY line_number DESC
                   LIMIT 1
                  ) AS d
    WHERE w.programs <> 'abcdefghijklmnop' OR w.line_number = 0
)
SELECT (SELECT programs FROM wolves WHERE line_number = 1) AS first_star,
       (SELECT programs FROM wolves WHERE line_number = 1000000000::bigint % (SELECT count(*)-1 FROM wolves)) AS second_star
;

DROP TABLE day16;
