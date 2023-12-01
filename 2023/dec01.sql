CREATE SCHEMA IF NOT EXISTS aoc2023;
SET SCHEMA 'aoc2023';
DROP TABLE IF EXISTS dec01;

CREATE TABLE dec01 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec01 (line) FROM '2023/dec01.input' NULL ''
VACUUM ANALYZE dec01;

/**************/
/* FIRST STAR */
/**************/

SELECT SUM(CAST(m.a || m.b AS INTEGER)) AS first_star
FROM dec01
CROSS JOIN LATERAL (VALUES (
    (regexp_match(line, '^[^\d]*(\d)'))[1],
    (regexp_match(line, '(\d)[^\d]*$'))[1])) AS m (a, b)
;

/***************/
/* SECOND STAR */
/***************/

WITH

conv (english, number) AS (
    VALUES ('one',   '1'), ('two',   '2'), ('three', '3'),
           ('four',  '4'), ('five',  '5'), ('six',   '6'),
           ('seven', '7'), ('eight', '8'), ('nine',  '9')
),

re (re) AS (SELECT string_agg(english, '|') FROM conv)

SELECT SUM(CAST(cfst.number || clst.number AS INTEGER)) AS second_star
FROM dec01
CROSS JOIN LATERAL regexp_match(line, '.*?(' || (TABLE re) || '|\d)') AS mfst
CROSS JOIN LATERAL regexp_match(line,  '.*(' || (TABLE re) || '|\d)') AS mlst
JOIN conv AS cfst ON mfst[1] IN (cfst.english, cfst.number)
JOIN conv AS clst ON mlst[1] IN (clst.english, clst.number)
;
