CREATE TABLE day05 (rownum serial, input text);

\COPY day05 (input) FROM 'input.txt'

/* You might want to set work_mem to something quite large */

WITH RECURSIVE
trampolines (jumps, steps, ip) AS (
    SELECT array_agg(input::integer ORDER BY rownum), 0, 1
    FROM day05
    UNION ALL
    SELECT jumps[:ip-1] || (jumps[ip] + 1) || jumps[ip+1:],
           steps+1,
           jumps[ip]+ip
    FROM trampolines
    WHERE jumps[ip] IS NOT NULL
)
SELECT steps AS first_star
FROM trampolines
ORDER BY steps DESC
LIMIT 1;

/*
 * The change for the second star is trivial.  However, since it stores up all
 * previous versions of the jumps array, it quickly ate up the 100GB free space
 * I had on my laptop.  A different version, using plpgsql was at around
 * 850,000 steps when I stopped it after seven hours.  I stopped it because
 * others told me their answers were around 27 million and I do not want to
 * wait that long.
 *
 * So while I have successfully completed the challenge, I am currently unable
 * to obtain the answer to validate my work on the website so I had to write a
 * version in plpgsql. :(
 */

-- WITH RECURSIVE
-- trampolines (jumps, steps, ip) AS (
--     SELECT array_agg(input::integer ORDER BY rownum), 0, 1
--     FROM day05
--     UNION ALL
--     SELECT jumps[:ip-1] || (jumps[ip] + CASE WHEN jumps[ip] >= 3 THEN -1 ELSE 1 END) || jumps[ip+1:],
--            steps+1,
--            jumps[ip]+ip
--     FROM trampolines
--     WHERE jumps[ip] IS NOT NULL
-- )
-- SELECT steps AS second_star
-- FROM trampolines
-- ORDER BY steps DESC
-- LIMIT 1;

CREATE OR REPLACE FUNCTION second_star()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    l_ip integer;
    l_new_ip integer;
    l_steps integer;
    l_trampolines integer[];
BEGIN
    l_ip := 1;
    l_steps := 0;
    l_trampolines := ARRAY(SELECT input::integer FROM day05 ORDER BY rownum);

    WHILE l_trampolines[l_ip] IS NOT NULL LOOP
        l_new_ip := l_ip + l_trampolines[l_ip];
        IF l_trampolines[l_ip] >= 3 THEN
            l_trampolines[l_ip] := l_trampolines[l_ip] - 1;
        ELSE
            l_trampolines[l_ip] := l_trampolines[l_ip] + 1;
        END IF;
        l_steps := l_steps + 1;
        l_ip := l_new_ip;
    END LOOP;

    RETURN l_steps;
END;
$function$;

SELECT second_star();

DROP FUNCTION second_star();
DROP TABLE day05;
