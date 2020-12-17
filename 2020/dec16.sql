DROP TABLE IF EXISTS dec16;
CREATE TABLE dec16 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec16 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/16/input';
VACUUM ANALYZE dec16;

\timing on

/* FIRST STAR */

WITH

ranges (range) AS (
    SELECT v.range
    FROM dec16,
         regexp_match(line, ': (\d+)-(\d+) or (\d+)-(\d+)$') AS m,
         LATERAL (VALUES (int8range(CAST(m[1] AS bigint), CAST(m[2] AS bigint), '[]')),
                         (int8range(CAST(m[3] AS bigint), CAST(m[4] AS bigint), '[]'))) AS v (range)
    WHERE m IS NOT NULL     
),

nearby_tickets (ticket) AS (
    SELECT line
    FROM dec16
    WHERE line_number > (
        SELECT line_number
        FROM dec16
        WHERE line = 'nearby tickets:')
)

SELECT sum(field)
FROM nearby_tickets AS n,
     LATERAL regexp_split_to_table(n.ticket, ',') AS r (f),
     LATERAL (VALUES (CAST(r.f AS bigint))) AS v (field)
WHERE NOT EXISTS (SELECT FROM ranges WHERE range @> field)
;

/* SECOND STAR */

WITH RECURSIVE

input AS (TABLE dec16),

ranges (field, range1, range2) AS (
    SELECT m[1],
           int8range(CAST(m[2] AS bigint), CAST(m[3] AS bigint), '[]'),
           int8range(CAST(m[4] AS bigint), CAST(m[5] AS bigint), '[]')
    FROM input,
         LATERAL regexp_match(line, '^(.*): (\d+)-(\d+) or (\d+)-(\d+)$') AS m
    WHERE m IS NOT NULL     
),

your_ticket (id, ticket) AS (
    SELECT line_number, line
    FROM input
    WHERE line_number = (
        SELECT line_number + 1
        FROM input
        WHERE line = 'your ticket:')
),

nearby_tickets (id, ticket) AS (
    SELECT line_number, line
    FROM input
    WHERE line_number > (
        SELECT line_number
        FROM input
        WHERE line = 'nearby tickets:')
),

invalid_tickets (id, ticket) AS (
    SELECT n.id, n.ticket
    FROM nearby_tickets AS n,
         LATERAL regexp_split_to_table(n.ticket, ',') AS r (value),
         LATERAL (VALUES (CAST(r.value AS bigint))) AS v (value)
    WHERE NOT EXISTS (SELECT FROM ranges WHERE range1 @> v.value OR range2 @> v.value)
),

valid_tickets (id, ticket) AS (
    TABLE nearby_tickets
    EXCEPT ALL
    TABLE invalid_tickets
),

possibilities (field, field_number) AS (
    SELECT DISTINCT field, field_number
    FROM (
        SELECT r.field,
               rx.field_number,
               r.range1 @> v.value OR r.range2 @> v.value,
               every(r.range1 @> v.value OR r.range2 @> v.value) OVER (PARTITION BY r.field, rx.field_number) AS all_match
        FROM valid_tickets AS vt
        CROSS JOIN LATERAL regexp_split_to_table(vt.ticket, ',') WITH ORDINALITY AS rx (value, field_number)
        CROSS JOIN LATERAL (VALUES (CAST(rx.value AS bigint))) AS v (value)
        CROSS JOIN ranges AS r
    )_
    WHERE all_match
),

distribution (iter, field, field_number, used) AS (
    VALUES (0, NULL, CAST(NULL AS bigint), CAST(ARRAY[] AS bigint[]))

    UNION ALL

    (
    WITH input AS (TABLE distribution)
    SELECT d.iter+1,
           p.field,
           min(p.field_number),
           d.used || min(p.field_number)
    FROM input AS d
    JOIN possibilities AS p ON p.field_number <> ALL (d.used)
    GROUP by d.iter, d.used, p.field
    HAVING count(*) = 1
    )
),

departure_fields (field_number) AS (
    SELECT field_number
    FROM distribution
    WHERE starts_with(field, 'departure')
),

ticket_values (row_num, value) AS (
    SELECT row_number() OVER (),
           CAST(u.value AS integer)
    FROM departure_fields AS df
    CROSS JOIN your_ticket AS yt
    CROSS JOIN LATERAL unnest(string_to_array(yt.ticket, ',')) WITH ORDINALITY AS u (value)
    WHERE field_number = u.ordinality
),

product_agg (row_num, result) AS (
    VALUES (CAST(0 AS bigint), CAST(1 AS bigint))

    UNION ALL

    SELECT v.row_num,
           p.result * v.value
    FROM product_agg AS p
    JOIN ticket_values AS v ON v.row_num = p.row_num + 1
)

SELECT result
FROM product_agg
ORDER BY row_num DESC
FETCH FIRST ROW ONLY
;
