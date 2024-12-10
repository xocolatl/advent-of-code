CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec10;

CREATE TABLE dec10 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec10 (line) FROM '2024/dec10.input' NULL ''
VACUUM ANALYZE dec10;

/**************/
/* FIRST STAR */
/**************/

WITH RECURSIVE

input (x, y, height) AS (
    SELECT ordinality,
           line_number,
           CAST(height AS INTEGER)
    FROM dec10
    CROSS JOIN LATERAL string_to_table(line, NULL) WITH ORDINALITY AS s (height, ordinality)
),

trails AS (
    SELECT x AS start_x, y AS start_y, x, y, height
    FROM input
    WHERE height = 0

    UNION DISTINCT

    SELECT t.start_x, t.start_y, i.x, i.y, i.height
    FROM trails AS t
    JOIN input AS i ON (i.x = t.x AND i.y BETWEEN t.y-1 AND t.y+1 OR i.y = t.y AND i.x BETWEEN t.x-1 AND t.x+1) AND i.height = t.height+1
)

SELECT COUNT(*) AS first_star
FROM trails
WHERE height = 9
;

/***************/
/* SECOND STAR */
/***************/
 
WITH RECURSIVE

input (x, y, height) AS (
    SELECT ordinality,
           line_number,
           CAST(height AS INTEGER)
    FROM dec10
    CROSS JOIN LATERAL string_to_table(line, NULL) WITH ORDINALITY AS s (height, ordinality)
),

trails AS (
    SELECT x AS start_x, y AS start_y, x, y, height
    FROM input
    WHERE height = 0

    UNION ALL

    SELECT t.start_x, t.start_y, i.x, i.y, i.height
    FROM trails AS t
    JOIN input AS i ON (i.x = t.x AND i.y BETWEEN t.y-1 AND t.y+1 OR i.y = t.y AND i.x BETWEEN t.x-1 AND t.x+1) AND i.height = t.height+1
)

SELECT COUNT(*) AS second_star
FROM trails
WHERE height = 9
;
