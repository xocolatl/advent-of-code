DROP TABLE IF EXISTS dec03;
CREATE TABLE dec03 (
    wire integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    directions text NOT NULL
);

\COPY dec03 (directions) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/3/input';
VACUUM ANALYZE dec03;

/* FIRST STAR */

SELECT abs(x) + abs(y) AS first_star
FROM (
    SELECT wire,
           sum(dx) over w AS x,
           sum(dy) over w AS y
    FROM (
        SELECT wire, o1,
               CASE substring(d for 1)
                WHEN 'R' THEN 1
                WHEN 'L' THEN -1
                ELSE 0
               END AS dx,
               CASE substring(d for 1)
                WHEN 'U' THEN 1
                WHEN 'D' THEN -1
                ELSE 0
               END AS dy,
               CAST(substring(d FROM 2) AS integer) AS distance
        FROM dec03
        CROSS JOIN regexp_split_to_table(directions, ',') WITH ORDINALITY AS directions(d, o1)
    ) AS _
    CROSS JOIN generate_series(1, distance) AS o2
    WINDOW w AS (PARTITION BY wire ORDER BY o1, o2)
) AS _
GROUP BY x, y
HAVING count(DISTINCT wire) = 2
ORDER BY abs(x) + abs(y)
FETCH FIRST ROW ONLY;

/* SECOND STAR */

SELECT sum(n) AS second_star
FROM (
    SELECT wire,
           row_number() over w AS n,
           sum(dx) over w AS x,
           sum(dy) over w AS y
    FROM (
        SELECT wire, o1,
               CASE substring(d for 1)
                WHEN 'R' THEN 1
                WHEN 'L' THEN -1
                ELSE 0
               END AS dx,
               CASE substring(d for 1)
                WHEN 'U' THEN 1
                WHEN 'D' THEN -1
                ELSE 0
               END AS dy,
               CAST(substring(d FROM 2) AS integer) AS distance
        FROM dec03
        CROSS JOIN regexp_split_to_table(directions, ',') WITH ORDINALITY AS directions(d, o1)
    ) AS _
    CROSS JOIN generate_series(1, distance) AS o2
    WINDOW w AS (PARTITION BY wire ORDER BY o1, o2)
) AS _
GROUP BY x, y
HAVING count(DISTINCT wire) = 2
ORDER BY sum(n)
FETCH FIRST ROW ONLY;
