CREATE SCHEMA IF NOT EXISTS aoc2024;
SET SCHEMA 'aoc2024';
DROP TABLE IF EXISTS dec06;

CREATE TABLE dec06 (
    line_number BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text
);

\COPY dec06 (line) FROM '2024/dec06.input' NULL ''
VACUUM ANALYZE dec06;

/**************/
/* FIRST STAR */
/**************/

WITH RECURSIVE

input (x, y, c) AS (
    SELECT ordinality, line_number, c
    FROM dec06
    CROSS JOIN LATERAL string_to_table(line, NULL) WITH ORDINALITY AS stt (c, ordinality)
    WHERE c <> '.'
),

dimensions (width, height) AS (
    /* This assumes the grid is square */
    SELECT LENGTH(line),
           line_number
    FROM dec06
    ORDER BY line_number DESC
    FETCH FIRST ROW ONLY
),

walk AS (
    SELECT 1 AS step,
           i.x AS prev_x,
           i.y AS prev_y,
           i.x,
           i.y,
           'up' AS direction
    FROM input AS i
    WHERE i.c = '^'

    UNION ALL

    SELECT w.step+1,
           w.x,
           w.y,
           vars.new_x,
           vars.new_y,
           vars.new_direction
    FROM walk AS w
    CROSS JOIN LATERAL (
        SELECT *
        FROM input AS i
        WHERE i.c = '#'
          AND CASE w.direction
                  WHEN 'up'    THEN i.x = w.x AND i.y < w.y
                  WHEN 'right' THEN i.y = w.y AND i.x > w.x
                  WHEN 'down'  THEN i.x = w.x AND i.y > w.y
                  WHEN 'left'  THEN i.y = w.y AND i.x < w.x
              END
        ORDER BY CASE w.direction
                     WHEN 'up'    THEN -i.y
                     WHEN 'right' THEN  i.x
                     WHEN 'down'  THEN  i.y
                     WHEN 'left'  THEN -i.x
                 END
        FETCH FIRST ROW ONLY
    ) AS i
    CROSS JOIN LATERAL (VALUES (
        CASE w.direction
            WHEN 'right' THEN i.x - 1
            WHEN 'left'  THEN i.x + 1
        ELSE
            w.x
        END,
        CASE w.direction
             WHEN 'up'   THEN i.y + 1
             WHEN 'down' THEN i.y - 1
        ELSE
            w.y
        END,
        CASE w.direction
            WHEN 'up'    THEN 'right'
            WHEN 'right' THEN 'down'
            WHEN 'down'  THEN 'left'
            WHEN 'left'  THEN 'up'
        END
    )) AS vars (new_x, new_y, new_direction)
),

walk_out AS (
    SELECT *
    FROM walk

    UNION ALL

    (SELECT w.step + 1,
            w.x,
            w.y,
            CASE w.direction
                WHEN 'right' THEN d.width
                WHEN 'left' THEN 1
            ELSE
                w.x
            END,
            CASE w.direction
                WHEN 'up' THEN 1
                WHEN 'down' THEN d.height
            END,
            NULL
     FROM walk AS w
     CROSS JOIN dimensions AS d
     ORDER BY step DESC
     FETCH FIRST ROW ONLY
    )
)

SELECT COUNT(DISTINCT (gx, gy)) AS first_star
FROM walk_out AS w,
     generate_series(LEAST(prev_x, x), GREATEST(prev_x, x)) AS gx,
     generate_series(LEAST(prev_y, y), GREATEST(prev_y, y)) AS gy
;

/***************/
/* SECOND STAR */
/***************/
 
WITH

input (x, y, c) AS (
    SELECT ordinality, line_number, c
    FROM dec06
    CROSS JOIN LATERAL string_to_table(line, NULL) WITH ORDINALITY AS stt (c, ordinality)
    WHERE c <> '.'
),

dimensions (width, height) AS (
    /* This assumes the grid is rectangular */
    SELECT LENGTH(line),
           line_number
    FROM dec06
    ORDER BY line_number DESC
    FETCH FIRST ROW ONLY
),

run AS (
    SELECT gx, gy
    FROM dimensions AS d
    CROSS JOIN LATERAL generate_series(1, d.width)  AS gx
    CROSS JOIN LATERAL generate_series(1, d.height) AS gy
    WHERE NOT EXISTS (SELECT FROM input WHERE (x, y) = (gx, gy))
      AND (
        WITH RECURSIVE

        input2 AS (
            TABLE input
            UNION ALL
            VALUES (gx, gy, '#')
        ),

        walk AS (
            SELECT 1 AS step,
                   i.x AS prev_x,
                   i.y AS prev_y,
                   i.x,
                   i.y,
                   'up' AS direction
            FROM input2 AS i
            WHERE i.c = '^'

            UNION ALL

            SELECT w.step+1,
                   w.x,
                   w.y,
                   vars.new_x,
                   vars.new_y,
                   vars.new_direction
            FROM walk AS w
            CROSS JOIN LATERAL (
                SELECT *
                FROM input2 AS i
                WHERE i.c = '#'
                  AND CASE w.direction
                          WHEN 'up'    THEN i.x = w.x AND i.y < w.y
                          WHEN 'right' THEN i.y = w.y AND i.x > w.x
                          WHEN 'down'  THEN i.x = w.x AND i.y > w.y
                          WHEN 'left'  THEN i.y = w.y AND i.x < w.x
                      END
                ORDER BY CASE w.direction
                             WHEN 'up'    THEN -i.y
                             WHEN 'right' THEN  i.x
                             WHEN 'down'  THEN  i.y
                             WHEN 'left'  THEN -i.x
                         END
                FETCH FIRST ROW ONLY
            ) AS i
            CROSS JOIN LATERAL (VALUES (
                CASE w.direction
                    WHEN 'right' THEN i.x - 1
                    WHEN 'left'  THEN i.x + 1
                ELSE
                    w.x
                END,
                CASE w.direction
                     WHEN 'up'   THEN i.y + 1
                     WHEN 'down' THEN i.y - 1
                ELSE
                    w.y
                END,
                CASE w.direction
                    WHEN 'up'    THEN 'right'
                    WHEN 'right' THEN 'down'
                    WHEN 'down'  THEN 'left'
                    WHEN 'left'  THEN 'up'
                END
            )) AS vars (new_x, new_y, new_direction)
        )
        CYCLE x, y, direction SET is_cycle USING path
        
        SELECT is_cycle
        FROM walk
        ORDER BY step DESC
        FETCH FIRST ROW ONLY
    )
)

SELECT COUNT(*) AS second_star
FROM run
;
