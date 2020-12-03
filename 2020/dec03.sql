DROP TABLE IF EXISTS dec03;
CREATE TABLE dec03 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec03 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/3/input';
VACUUM ANALYZE dec03;

\timing on

/* FIRST STAR */

SELECT count(*)
FROM dec03 AS d
WHERE SUBSTRING(d.line FROM (3 * (d.line_number - 1)) % length(d.line) + 1 FOR 1) = '#'
;

/* SECOND STAR */

SELECT (count(*) FILTER (WHERE SUBSTRING(d.line FROM (1 * (d.line_number - 1)) % length(d.line) + 1 FOR 1) = '#') *
        count(*) FILTER (WHERE SUBSTRING(d.line FROM (3 * (d.line_number - 1)) % length(d.line) + 1 FOR 1) = '#') *
        count(*) FILTER (WHERE SUBSTRING(d.line FROM (5 * (d.line_number - 1)) % length(d.line) + 1 FOR 1) = '#') *
        count(*) FILTER (WHERE SUBSTRING(d.line FROM (7 * (d.line_number - 1)) % length(d.line) + 1 FOR 1) = '#') *
        count(*) FILTER (WHERE SUBSTRING(d.line FROM (d.line_number / 2) % length(d.line) + 1 FOR 1) = '#' AND line_number % 2 = 1))
FROM dec03 AS d
;
