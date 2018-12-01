CREATE TABLE day04 (rownum serial, input text);

\COPY day04 (input) FROM 'input.txt'

/* Let's abuse the system a little bit, just for quick n' dirty fun */
SELECT count(*) AS first_star
FROM day04 AS d,
     to_tsvector('simple', d.input) AS v
WHERE v::text !~ ',';

/* There is probably a less roundabout way to do this */
WITH
as_arrays AS (
    SELECT row_number() over () AS id,
           string_to_array(d.input, ' ') AS words
    FROM day04 AS d
),
unrolled AS (
    SELECT aa.id, u.word
    FROM as_arrays AS aa,
         unnest(aa.words) AS u(word)
),
sorted_words AS (
    SELECT u.id,
           (SELECT string_agg(letter, '' ORDER BY letter) FROM regexp_split_to_table(u.word, '') AS letter) AS word
    FROM unrolled AS u
),
counts AS (
    SELECT id,
           count(*) AS all_count,
           count(DISTINCT word) AS distinct_count
    FROM sorted_words
    GROUP BY id
)
SELECT count(*) FILTER (WHERE all_count = distinct_count) AS second_star
FROM counts;

DROP TABLE day04;
