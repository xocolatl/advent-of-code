CREATE TABLE day22 (rownum serial, input text);

\COPY day22 (input) FROM 'input.txt'

WITH RECURSIVE
input AS (
    SELECT u.ord-13 AS x,
           d.rownum-13 AS y,
           u.value
    FROM day22 AS d,
         unnest(string_to_array(d.input, null)) WITH ORDINALITY AS u(value, ord)
),
loop AS (
    SELECT 0 AS step,
           0 AS x,
           0 AS y,
           0 AS dx,
           -1 AS dy,
           jsonb_object_agg(x||','||y, value) as board,
           0 AS infected
    FROM input
    WHERE value = '#'
    UNION ALL
    SELECT step+1,
           CASE WHEN NOT board ? (x||','||y) THEN x + dy ELSE x - dy END,
           CASE WHEN NOT board ? (x||','||y) THEN y - dx ELSE y + dx END,
           CASE WHEN NOT board ? (x||','||y) THEN dy ELSE -dy END,
           CASE WHEN NOT board ? (x||','||y) THEN -dx ELSE dx END,
           CASE WHEN NOT board ? (x||','||y) THEN board || jsonb_build_object(x||','||y, '#') ELSE board - (x||','||y) END,
           CASE WHEN NOT board ? (x||','||y) THEN 1 ELSE 0 END + infected
    FROM loop
    WHERE step < 10000
)
SELECT infected as first_star
FROM loop
WHERE step = 10000
ORDER BY step;

DROP TABLE day22;
