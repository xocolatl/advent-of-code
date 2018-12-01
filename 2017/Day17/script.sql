CREATE TABLE day17 (rownum serial, input text);

\COPY day17 (input) FROM 'input.txt'

WITH RECURSIVE
spin AS (
    SELECT ARRAY[0] AS lock,
           0 AS pos,
           1 AS len,
           (SELECT input::integer FROM day17) AS step
    UNION ALL
    SELECT lock[:(pos+step)%len+1] || ARRAY[len] || lock[(pos+step)%len+2:],
           (pos+step)%len+1,
           len+1,
           step
    FROM spin
    WHERE len <= 2017
)
SELECT lock[(pos+1)%len+1] AS first_star
FROM spin
ORDER BY len DESC
LIMIT 1;

WITH RECURSIVE
spin AS (
    SELECT null::integer as result,
           0 AS pos,
           1 AS len,
           (SELECT input::integer FROM day17) AS step
    UNION ALL
    SELECT CASE WHEN (pos+step)%len+1 = 1 THEN len ELSE result END,
           (pos+step)%len+1,
           len+1,
           step
    FROM spin
    WHERE len <= 50000000
)
SELECT result
FROM spin
ORDER BY len DESC
LIMIT 1;

DROP TABLE day17;
