CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec08;

CREATE TABLE dec08 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec08 (line) FROM '2024/dec08.input' NULL ''
VACUUM ANALYZE dec08;

/**************/
/* FIRST STAR */
/**************/

WITH

input (antenna, x, y, frequency) AS (
    SELECT ROW_NUMBER() OVER (ORDER BY ordinality, line_number),
           ordinality,
           line_number,
           frequency
    FROM dec08
    CROSS JOIN LATERAL string_to_table(line, NULL) WITH ORDINALITY AS s (frequency, ordinality)
    WHERE frequency <> '.'
),

dimensions (width, height) AS (
    SELECT LENGTH(line),
           line_number
    FROM dec08
    ORDER BY line_number DESC
    FETCH FIRST ROW ONLY
),

antinodes AS (
    SELECT DISTINCT gx, gy
    FROM dimensions AS d
    CROSS JOIN LATERAL generate_series(1, d.width)  AS gx
    CROSS JOIN LATERAL generate_series(1, d.height) AS gy
    CROSS JOIN input AS i1
    JOIN input AS i2 ON i2.frequency = i1.frequency AND i2.antenna <> i1.antenna
    WHERE i2.x - i1.x = i1.x - gx
      AND i2.y - i1.y = i1.y - gy
)

SELECT COUNT(*) AS first_star
FROM antinodes
;

/***************/
/* SECOND STAR */
/***************/
 
WITH

input (antenna, x, y, frequency) AS (
    SELECT ROW_NUMBER() OVER (ORDER BY ordinality, line_number),
           CAST(ordinality AS NUMERIC),
           CAST(line_number AS NUMERIC),
           frequency
    FROM dec08
    CROSS JOIN LATERAL string_to_table(line, NULL) WITH ORDINALITY AS s (frequency, ordinality)
    WHERE frequency <> '.'
),

dimensions (width, height) AS (
    SELECT LENGTH(line),
           line_number
    FROM dec08
    ORDER BY line_number DESC
    FETCH FIRST ROW ONLY
),

antinodes AS (
    SELECT DISTINCT gx, gy
    FROM dimensions AS d
    CROSS JOIN LATERAL generate_series(1, d.width)  AS gx
    CROSS JOIN LATERAL generate_series(1, d.height) AS gy
    CROSS JOIN input AS i1
    JOIN input AS i2 ON i2.frequency = i1.frequency AND i2.antenna <> i1.antenna
    WHERE (i2.y - gy) / NULLIF(i2.x - gx, 0) = (i2.y - i1.y) / NULLIF(i2.x - i1.x, 0)
)

SELECT COUNT(*) AS second_star
FROM antinodes
;
