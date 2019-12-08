DROP TABLE IF EXISTS dec08;
CREATE TABLE dec08 (
    pixels text NOT NULL
);

\COPY dec08 (pixels) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/8/input';
VACUUM ANALYZE dec08;

-- Using Postgres functions such as regexp_split_to_table() WITH ORDINALITY is
-- several orders of magnitude faster than this Standard SQL version.

/* FIRST STAR */

WITH RECURSIVE

pixels (n, layer, value, pixels) AS (
    SELECT 0,
           0,
           CAST(substring(pixels FOR 1) AS integer),
           substring(pixels FROM 2)
    FROM dec08

    UNION ALL

    SELECT n + 1,
           n / (25 * 6),
           CAST(substring(pixels FOR 1) AS integer),
           substring(pixels FROM 2)
    FROM pixels
    WHERE pixels <> ''
)

SELECT count(*) FILTER (WHERE value = 1) * count(*) FILTER (WHERE value = 2) AS first_star
FROM pixels
GROUP BY layer
ORDER BY count(*) FILTER (WHERE value = 0)
FETCH FIRST ROW ONLY
;

/* SECOND STAR */

WITH RECURSIVE

pixels (n, layer, x, y, value, pixels) AS (
    SELECT 0,
           0,
           0,
           0,
           CAST(substring(pixels FOR 1) AS integer),
           substring(pixels FROM 2)
    FROM dec08

    UNION ALL

    SELECT n + 1,
           (n + 1) / (25 * 6),
           (n + 1) % 25,
           (n + 1) / 25 % 6,
           CAST(substring(pixels FOR 1) AS integer),
           substring(pixels FROM 2)
    FROM pixels
    WHERE pixels <> ''
)

SELECT string_agg(char, '' ORDER BY x) AS second_star
FROM (
    SELECT DISTINCT x, y, CASE first_value WHEN '0' THEN ' ' WHEN '1' THEN '#' END AS char
    FROM (
        SELECT n, layer, x, y, value, first_value(value) OVER w
        FROM pixels
        WHERE value <> 2
        WINDOW w AS (PARTITION BY x, y ORDER BY layer)
    ) AS _
) AS _
GROUP BY y
ORDER BY y
;
