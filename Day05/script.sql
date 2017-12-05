CREATE TABLE day05 (input text);

\COPY day05 FROM 'input.txt'

/* You might want to set work_mem to something quite large */

WITH RECURSIVE
trampolines (jumps, steps, ip) AS (
    SELECT array_agg(input::integer ORDER BY ctid), 0, 1
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
 * to obtain the answer to validate my work on the website. :(
 */

-- WITH RECURSIVE
-- trampolines (jumps, steps, ip) AS (
--     SELECT array_agg(input::integer ORDER BY ctid), 0, 1
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

DROP TABLE day05;
