CREATE TABLE day02 (input text);

/* The delimiter is just something other than TAB */
\COPY day02 FROM 'input.txt' (DELIMITER ';')

/* It would be really nice if greatest() and least() were variadic functions instead of baked into the grammar */
SELECT sum((SELECT max(x::integer) FROM unnest(a) AS u(x)) - (SELECT min(x::integer) FROM unnest(a) AS u(x))) AS first_star
FROM day02 AS d,
     string_to_array(input, chr(9)) AS a;

SELECT sum(numerator.n / denominator.d) AS second_star
FROM day02 AS d,
     unnest(string_to_array(d.input, chr(9))::integer[]) AS numerator(n),
     unnest(string_to_array(d.input, chr(9))::integer[]) AS denominator(d)
WHERE numerator.n > denominator.d
  AND mod(numerator.n, denominator.d) = 0;

DROP TABLE day02;
