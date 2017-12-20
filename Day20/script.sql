CREATE TABLE day20 (rownum serial, input text);

\COPY day20 (input) FROM 'input.txt'

/* Both of these queries have shameful, arbitrary stopping points */

WITH
input AS (
    SELECT rownum,
           match[1]::integer AS px, match[2]::integer AS py, match[3]::integer AS pz,
           match[4]::integer AS vx, match[5]::integer AS vy, match[6]::integer AS vz,
           match[7]::integer AS ax, match[8]::integer AS ay, match[9]::integer AS az,
           10000000::bigint AS t
    FROM day20,
         regexp_match(input, '^p=<(-?\d+),(-?\d+),(-?\d+)>, v=<(-?\d+),(-?\d+),(-?\d+)>, a=<(-?\d+),(-?\d+),(-?\d+)>$') AS match
)
SELECT rownum-1 AS first_star
FROM input
ORDER BY abs((ax*t*(t+1)/2 + (vx+ax)*t + px)) + abs((ay*t*(t+1)/2 + (vy+ay)*t + py)) + abs((az*t*(t+1)/2 + (vz+az)*t + pz))
LIMIT 1;

WITH RECURSIVE
input AS (
    SELECT rownum,
           match[1]::integer AS px, match[2]::integer AS py, match[3]::integer AS pz,
           match[4]::integer AS vx, match[5]::integer AS vy, match[6]::integer AS vz,
           match[7]::integer AS ax, match[8]::integer AS ay, match[9]::integer AS az
    FROM day20,
         regexp_match(input, '^p=<(-?\d+),(-?\d+),(-?\d+)>, v=<(-?\d+),(-?\d+),(-?\d+)>, a=<(-?\d+),(-?\d+),(-?\d+)>$') AS match
),
loop AS (
    SELECT 0 AS tick,
           px, py, pz,
           vx, vy, vz,
           ax, ay, az,
           count(*) OVER (PARTITION BY px, py, pz) AS collisions
    FROM input
    UNION ALL
    SELECT tick+1,
           px+vx+ax, py+vy+ay, pz+vz+az,
           vx+ax, vy+ay, vz+az,
           ax, ay, az,
           count(*) OVER (PARTITION BY px+vx+ax, py+vy+ay, pz+vz+az)
    FROM loop
    WHERE collisions = 1
      AND tick < 100
)
SELECT count(*) AS second_star
FROM loop
WHERE tick = (SELECT max(tick) FROM loop);

DROP TABLE day20;
