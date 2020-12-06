DROP TABLE IF EXISTS dec06;
CREATE TABLE dec06 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    form text NOT NULL
);

\COPY dec06 (form) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/6/input';
VACUUM ANALYZE dec06;

\timing on

/* FIRST STAR */

WITH

input (grp, form) AS (
    SELECT count(*) FILTER (WHERE form = '') OVER (ORDER BY line_number),
           form
    FROM dec06 AS d
)

SELECT sum(count)
FROM (
    SELECT grp, count(DISTINCT question)
    FROM input,
         LATERAL unnest(string_to_array(form, NULL)) AS u (question)
    GROUP BY grp
) AS _
;

/* SECOND STAR */

WITH

input AS (
    SELECT *,
           count(*) FILTER (WHERE form = '') OVER (ORDER BY line_number) AS grp
    FROM dec06
),

people_in_group (grp, num_people) AS (
    SELECT grp,
           count(*) FILTER (WHERE form <> '')
    FROM input
    GROUP BY grp
),

questions_in_group (grp, question, num_questions) AS (
    SELECT grp, question, count(*)
    FROM input,
         LATERAL unnest(string_to_array(form, null)) AS u (question)
    GROUP BY grp, question
)

SELECT sum(count)
FROM (
    SELECT q.grp, count(*)
    FROM questions_in_group AS q
    JOIN people_in_group AS p ON (p.grp, p.num_people) = (q.grp, q.num_questions)
    GROUP BY q.grp
) AS _
;
