DROP TABLE IF EXISTS dec04;
CREATE TABLE dec04 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec04 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/4/input';
VACUUM ANALYZE dec04;

\timing on

/* FIRST STAR */

WITH

input (grp, key, value) AS (
    SELECT COALESCE(max(line_number) FILTER (WHERE line = '') OVER (ORDER BY line_number), 1) AS grp,
           s[1] AS key,
           s[2] AS value
    from dec04,
         LATERAL regexp_split_to_table(line, ' ') AS r,
         LATERAL string_to_array(r, ':') AS s
),

passports (grp, keys) AS (
    SELECT grp, array_agg(key)
    FROM input
    GROUP BY grp
)

SELECT count(*)
FROM passports
WHERE keys @> '{byr,iyr,eyr,hgt,hcl,ecl,pid}'
;

/* SECOND STAR */

WITH

input (grp, key, value) AS (
    SELECT COALESCE(max(line_number) FILTER (WHERE line = '') OVER (ORDER BY line_number), 1) AS grp,
           s[1] AS key,
           s[2] AS value
    from dec04,
         LATERAL regexp_split_to_table(line, ' ') AS r,
         LATERAL string_to_array(r, ':') AS s
),

patterns (key, pattern) AS (
    VALUES ('byr', '^\d{4}$'),
           ('iyr', '^\d{4}$'),
           ('eyr', '^\d{4}$'),
           ('hgt', '^(\d+)(cm|in)$'),
           ('hcl', '^#[0-9a-f]{6}$'),
           ('ecl', '^(amb|blu|brn|gry|grn|hzl|oth)$'),
           ('pid', '^\d{9}$')
),

passports (grp, keys) AS (
    SELECT i.grp,
           array_agg(i.key)
    FROM input AS i
    JOIN patterns AS p ON p.key = i.key
    CROSS JOIN LATERAL regexp_match(i.value, p.pattern) AS m
    WHERE CASE i.key
              WHEN 'byr' THEN CAST(m[1] AS integer) BETWEEN 1920 AND 2002
              WHEN 'iyr' THEN CAST(m[1] AS integer) BETWEEN 2010 AND 2020
              WHEN 'eyr' THEN CAST(m[1] AS integer) BETWEEN 2020 AND 2030
              WHEN 'hgt' THEN
                  CASE m[2]
                      WHEN 'cm' THEN CAST(m[1] AS integer) BETWEEN 150 AND 193
                      WHEN 'in' THEN CAST(m[1] AS integer) BETWEEN 59 AND 76
                  END
              ELSE m IS NOT NULL
          END
    GROUP BY i.grp
)

SELECT count(*)
FROM passports
WHERE keys @> '{byr,iyr,eyr,hgt,hcl,ecl,pid}'
;
