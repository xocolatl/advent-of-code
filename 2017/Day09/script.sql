CREATE TABLE day09 (rownum serial, input text);

\COPY day09 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT position::integer,
           letter
    FROM day09,
         unnest(string_to_array(input, null)) WITH ORDINALITY AS u(letter, position)
),
state_machine AS (
    SELECT 0 AS position,
           null::text AS letter,
           false AS in_garbage,
           false AS was_in_garbage,
           false AS delete_next,
           false AS deleted,
           0 AS depth
    UNION ALL
    SELECT i.position,
           i.letter,
           sm.in_garbage AND NOT (i.letter = '>' AND NOT sm.delete_next) OR (i.letter = '<' AND NOT sm.delete_next),
           sm.in_garbage,
           i.letter = '!' AND sm.in_garbage AND NOT sm.delete_next,
           sm.delete_next,
           sm.depth + CASE WHEN i.letter = '{' AND NOT sm.in_garbage THEN 1 WHEN i.letter = '}' AND NOT sm.in_garbage THEN -1 ELSE 0 END
    FROM state_machine AS sm
    JOIN input AS i ON i.position = sm.position + 1
),
first_star (first_star) AS (
	SELECT sum(depth+1) FILTER (WHERE letter = '}' AND NOT in_garbage) OVER (ORDER BY position)
	FROM state_machine
	ORDER BY position DESC
	LIMIT 1
),
second_star (second_star) AS (
	SELECT count(*) FILTER (WHERE in_garbage AND was_in_garbage) OVER (ORDER BY position)
	FROM state_machine
	WHERE NOT delete_next AND NOT deleted
	ORDER BY position DESC
	LIMIT 1
)
SELECT (TABLE first_star), (TABLE second_star);

DROP TABLE day09;
