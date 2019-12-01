DROP TABLE IF EXISTS dec01;
CREATE TABLE dec01 (
    line_number bigint GENERATED ALWAYS AS IDENTITY,
    mass bigint NOT NULL
);

\COPY dec01 (mass) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/1/input';

/* FIRST STAR */

SELECT sum(mass / 3 - 2) AS first_star
FROM dec01;

/* SECOND STAR */

/*
 * Any mass that would require negative fuel should instead be treated as if it
 * requires zero fuel; the remaining mass, if any, is instead handled by
 * wishing really hard, which has no mass and is outside the scope of this
 * calculation.
 *
 * It turns out that this means we can discard any mass of 8 or below because
 * 8 / 3 - 2 = 0.
 */

WITH RECURSIVE

fuel (mass) AS (
    SELECT mass / 3 - 2
    FROM dec01
    WHERE dec01.mass > 8

    UNION ALL

    SELECT fuel.mass / 3 - 2
    FROM fuel
    WHERE fuel.mass > 8
)

SELECT sum(mass) AS second_star
FROM fuel;
