CREATE TABLE day12 (rownum serial, input text);

\COPY day12 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT match[1]::integer AS id,
           string_to_array(match[2], ', ')::integer[] AS pipes
    FROM day12,
         regexp_match(input, '^(\d+) <-> (.*)$') AS match
),
loop AS (
    SELECT id, pipes, ARRAY[id] AS seen
    FROM input
    WHERE id = 0
    UNION ALL
    SELECT i.id, i.pipes, l.seen || i.id
    FROM input AS i
    JOIN loop AS l ON i.id = ANY (l.pipes)
    WHERE i.id <> ALL (l.seen)
)
SELECT count(*) AS first_star
FROM loop;

/* With many thanks to https://github.com/zr40 for helping me get rid of the
 * plpgsql. */

WITH RECURSIVE
input AS (
    SELECT match[1]::integer AS program,
           string_to_array(match[2], ', ')::integer[] AS linked_to
    FROM day12,
         regexp_match(input, '^(\d+) <-> (.*)$') AS match
),
path AS (
  SELECT program, link
  from input,
       unnest(linked_to) AS link
  UNION
  SELECT path.program, u.link
  FROM path
  JOIN input ON input.program = path.link
  CROSS JOIN unnest(input.linked_to) AS u(link)
)
SELECT count(*) AS second_star
FROM (
    SELECT DISTINCT array_agg(link ORDER BY link) AS links
    FROM path
    GROUP BY program
) _;

DROP TABLE day12;
