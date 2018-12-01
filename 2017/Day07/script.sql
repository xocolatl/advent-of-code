CREATE TABLE day07 (rownum serial, input text);

\COPY day07 (input) FROM 'input.txt'

WITH
input (name, weight, supporting) AS (
    SELECT match[1],
           match[2]::integer,
           string_to_array(match[3], ', ')::text[]
    FROM day07,
         regexp_match(input, '(\w+) \((\d+)\)(?: -> (.*))?') AS match
)
SELECT name AS first_star
FROM input
WHERE NOT EXISTS (
    SELECT FROM input AS parent
    WHERE input.name = ANY (parent.supporting));

/*
 * After two days of trying to express this in SQL, I gave up and wrote some
 * plpgsql functions.
 */

CREATE OR REPLACE FUNCTION second_star()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    l_result integer;
BEGIN
	CREATE TEMPORARY TABLE IF NOT EXISTS input (
		name text,
		weight integer,
		supporting text[]
	) ON COMMIT DROP;

    INSERT INTO input
        SELECT match[1],
               match[2]::integer,
               string_to_array(match[3], ', ')::text[]
        FROM day07,
             regexp_match(input, '(\w+) \((\d+)\)(?: -> (.*))?') AS match;

    CREATE TEMPORARY TABLE IF NOT EXISTS cache (
        name text,
        weight integer
    ) ON COMMIT DROP;

    SELECT weight - diff AS second_star
    FROM (
        SELECT (array_agg(supporting ORDER BY total_weight DESC))[1] AS heaviest,
               max(total_weight) - min(total_weight) AS diff,
               array_agg(name) OVER () AS names
        FROM (
            SELECT i.name,
                   u.supporting,
                   get_total_weight(u.supporting) AS total_weight
            FROM input i,
                 unnest(supporting) AS u(supporting)
        ) _
        GROUP BY name
        HAVING count(DISTINCT total_weight) > 1
    ) _
    JOIN input i ON name = heaviest
    WHERE heaviest <> ALL (names)
    INTO l_result;

    RETURN l_result;
END;
$function$;

CREATE OR REPLACE FUNCTION get_total_weight(text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    l_result integer;
    l_supporting text[];
    l_name text;
BEGIN
    SELECT weight
    INTO l_result
    FROM cache
    WHERE name = $1;

    IF FOUND THEN
        RETURN l_result;
    END IF;

    SELECT weight, supporting
    INTO l_result, l_supporting
    FROM input
    WHERE name = $1;

    IF l_supporting IS NOT NULL THEN
        FOREACH l_name IN ARRAY l_supporting LOOP
            l_result := l_result + get_total_weight(l_name);
        END LOOP;
    END IF;

    INSERT INTO cache
    VALUES ($1, l_result);

    RETURN l_result;
END;
$function$;

SELECT second_star();

DROP FUNCTION get_total_weight(text);
DROP FUNCTION second_star();
DROP TABLE day07;
