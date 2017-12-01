CREATE TABLE day01 (input text);

\COPY day01 FROM 'input.txt'

SELECT coalesce(sum(digit) FILTER (WHERE digit = next_digit), 0) AS first_star
FROM (
    SELECT u.digit::integer,
           coalesce(lead(u.digit) OVER w, first_value(u.digit) OVER w)::integer AS next_digit
    FROM day01 AS d,
         unnest(string_to_array(d.input, null)) WITH ORDINALITY AS u (digit, ordinality)
    WINDOW w AS (ORDER BY u.ordinality)
) _;


SELECT sum(digit) FILTER (WHERE ordinality <= length(input) AND digit = next_digit) AS second_star
FROM (
    SELECT d.input,
           u.digit::integer,
           u.ordinality,
           coalesce(lead(u.digit, length(d.input)/2) OVER w)::integer AS next_digit
    FROM day01 AS d,
         unnest(string_to_array(d.input || d.input, null)) WITH ORDINALITY AS u (digit, ordinality)
    WINDOW w AS (ORDER BY u.ordinality)
) _;

DROP TABLE day01;
