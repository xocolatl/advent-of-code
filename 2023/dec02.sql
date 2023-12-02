CREATE SCHEMA IF NOT EXISTS aoc2023;
SET SCHEMA 'aoc2023';
DROP TABLE IF EXISTS dec02;

CREATE TABLE dec02 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec02 (line) FROM '2023/dec02.input' NULL ''
VACUUM ANALYZE dec02;

/**************/
/* BOTH STARS */
/**************/

WITH

input (game, subset, red, green, blue) AS (
    SELECT CAST(m1[1] AS INTEGER) AS game,
           m2.ordinality AS subset,
           SUM(CASE WHEN m4[2] = 'red'   THEN CAST(m4[1] AS INTEGER) ELSE 0 END),
           SUM(CASE WHEN m4[2] = 'green' THEN CAST(m4[1] AS INTEGER) ELSE 0 END),
           SUM(CASE WHEN m4[2] = 'blue'  THEN CAST(m4[1] AS INTEGER) ELSE 0 END)
    FROM dec02,
         regexp_match(line, '^Game (\d+): (.*)$') AS m1,
         regexp_split_to_table(m1[2], '; ') WITH ORDINALITY AS m2,
         regexp_split_to_table(m2, ', ') AS m3,
         regexp_match(m3, '(\d+) (.*)') AS m4
    GROUP BY game, subset
),

possibles (game) AS (
    SELECT game
    FROM input
    GROUP BY game
    HAVING MAX(red) <= 12
       AND MAX(green) <= 13
       AND MAX(blue) <= 14
),

powers (power) AS (
    SELECT MAX(red) * MAX(green) * MAX(blue)
    FROM input
    GROUP BY game
)

VALUES (
    (SELECT SUM(game)  AS first_star  FROM possibles),
    (SELECT SUM(power) AS second_star FROM powers)
)
;
