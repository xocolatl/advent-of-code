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

SELECT sum(fuel.mass) AS second_star
FROM dec01
CROSS JOIN LATERAL (
    WITH RECURSIVE
    fuel (mass) AS (
        SELECT dec01.mass / 3 - 2
        UNION ALL
        SELECT fuel.mass / 3 - 2
        FROM fuel
        WHERE fuel.mass > 0
    )
    SELECT mass
    FROM fuel
    WHERE fuel.mass > 0
) AS fuel;
