DROP TABLE IF EXISTS dec14;
CREATE TABLE dec14 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec14 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/14/input';
VACUUM ANALYZE dec14;

\timing on

/* FIRST STAR */

WITH RECURSIVE

input (line_number, line, new_mask, zeroes, ones, addr, value) AS (
    SELECT d.line_number,
           d.line,
           (new_mask.*) IS NOT NULL,
           new_mask.zeroes,
           new_mask.ones,
           set_mem.addr,
           set_mem.value
    FROM dec14 AS d
    LEFT JOIN lateral (
        SELECT sum(1::bigint << (ord::integer-1)) FILTER (WHERE bit = '0')::bigint,
               sum(1::bigint << (ord::integer-1)) FILTER (WHERE bit = '1')::bigint
        FROM unnest(string_to_array(reverse(d.line), null)) with ordinality AS u (bit, ord)
        WHERE d.line ~ '^mask = '
          AND u.bit <> 'X'
    ) AS new_mask (zeroes, ones) ON true
    LEFT JOIN LATERAL (
        SELECT m[1]::bigint, m[2]::bigint
        FROM regexp_match(d.line, '^mem\[(\d+)] = (\d+)$') AS m
    ) AS set_mem(addr, value) ON true
),

exec (line_number, mem, zeroes, ones) AS (
    VALUES (0, jsonb '{}', null::bigint, null::bigint)

    UNION ALL

    SELECT i.line_number,
           CASE WHEN i.new_mask THEN mem ELSE jsonb_set(mem, array[i.addr::text], 
            to_jsonb(((i.value | e.ones) & ~e.zeroes) & 68719476735::bigint)
           ) END,
           CASE WHEN i.new_mask THEN i.zeroes ELSE e.zeroes END,
           CASE WHEN i.new_mask THEN i.ones ELSE e.ones END
    FROM exec AS e
    JOIN input AS i ON i.line_number = e.line_number+1
),

final_mem (mem) AS (
    SELECT mem
    FROM exec
    ORDER BY line_number DESC
    FETCH FIRST ROW ONLY
),

output AS (
SELECT sum(value::bigint)
FROM final_mem,
     lateral jsonb_each_text(mem)
)

SELECT *
FROM output
;

/* SECOND STAR */

WITH RECURSIVE

input (line_number, mask, addr, value) AS (
    SELECT *,
           max(line_number) FILTER (WHERE mask IS NOT NULL) OVER (ORDER BY line_number) AS mask_line
    FROM (
        SELECT line_number,
               SUBSTRING(line FROM '^mask = (.*)$') AS mask,
               CAST(CAST(CAST(SUBSTRING(line FROM '^mem\[(\d+)]') AS bigint) AS bit(36)) AS text) AS addr,
               CAST(SUBSTRING(line FROM '^mem\[\d+] = (\d+)$') AS bigint) AS value
        FROM dec14
    ) AS _
),

floats (line_number, addr, value) AS (
    SELECT i.line_number,
           m.addr,
           i.value
    FROM input AS i
    CROSS JOIN LATERAL (
        SELECT mask
        FROM input
        WHERE line_number = i.mask_line
    ) AS j
    CROSS JOIN LATERAL (
        SELECT string_agg(CASE WHEN m = '0' THEN a ELSE m END, '' ORDER BY o)
        FROM ROWS FROM (unnest(
            string_to_array(j.mask, null),
            string_to_array(i.addr, null))
        ) WITH ORDINALITY AS u (m, a, o)
    ) AS m (addr)
    WHERE i.mask IS NULL
),

unroll AS (
    TABLE floats

    UNION ALL
    
    SELECT u.line_number,
           x.addr,
           u.value
    FROM unroll AS u
    CROSS JOIN (VALUES ('0'), ('1')) AS v (b)
    CROSS JOIN LATERAL regexp_replace(u.addr, 'X', b) AS x (addr)
    WHERE u.addr ~ 'X'
),

assignments (addr, value) AS (
    SELECT DISTINCT ON (addr) addr, value
    FROM (
        SELECT line_number,
               CAST(CAST(addr AS bit(36)) AS bigint) AS addr,
               value
        FROM unroll
        WHERE addr !~ 'X'
    ) AS _
    ORDER BY addr, line_number DESC
)

SELECT sum(value)
FROM assignments
;
