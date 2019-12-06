DROP TABLE IF EXISTS dec06;
CREATE TABLE dec06 (
    orbits text NOT NULL
);

\COPY dec06 (orbits) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2019/day/6/input';
VACUUM ANALYZE dec06;

/* FIRST STAR */

WITH RECURSIVE

input (planet, orbiting) AS (
    SELECT substring(orbits FROM position(')' IN orbits) + 1),
           substring(orbits FOR  position(')' IN orbits) - 1)
    FROM dec06
),

walker (planet, orbiting) AS (
    SELECT planet, orbiting
    FROM input

    UNION ALL

    SELECT i.planet, i.orbiting
    FROM input AS i
    JOIN walker AS w ON w.orbiting = i.planet
)

SELECT count(*) AS first_star
FROM walker
;

/* SECOND STAR */

WITH RECURSIVE

input (planet, orbiting) AS (
    SELECT substring(orbits FROM position(')' IN orbits) + 1),
           substring(orbits FOR  position(')' IN orbits) - 1)
    FROM dec06
),

walker (you_chain, san_chain) AS (
    VALUES (ARRAY['YOU'], ARRAY['SAN'])

    UNION ALL

    SELECT (SELECT orbiting FROM input WHERE planet = you_chain[1]) || you_chain,
           (SELECT orbiting FROM input WHERE planet = san_chain[1]) || san_chain
    FROM walker
    WHERE NOT (you_chain && san_chain)
)

/*
 * We need to remove 4 from the chain length:
 *   - YOU
 *   - SAN
 *   - the lowest common ancestor
 *   - the first step
 */
SELECT array_length(you.you_chain || san.san_chain, 1) - 4 AS second_star
FROM walker AS you
JOIN walker AS san ON san.san_chain[1] = you.you_chain[1]
;
