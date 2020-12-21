DROP TABLE IF EXISTS dec21;
CREATE TABLE dec21 (
    line_number integer NOT NULL GENERATED ALWAYS AS IDENTITY,
    line text NOT NULL
);

\COPY dec21 (line) FROM PROGRAM 'curl -b session.cookie https://adventofcode.com/2020/day/21/input';
VACUUM ANALYZE dec21;

\timing on

/* FIRST STAR */

WITH RECURSIVE

input (id, ingredient, allergen) AS (
    SELECT line_number, ingredient, allergen
    FROM dec21,
         LATERAL regexp_match(line, '^([^(]+) \(contains (.+)\)$') AS m,
         LATERAL regexp_split_to_table(m[1], ' ') AS ingredient,
         LATERAL regexp_split_to_table(m[2], ', ') AS allergen
),

find_matches (iter, allergens, ingredients) AS (
    VALUES (0, CAST(ARRAY[] AS text[]), CAST(ARRAY[] AS text[]))

    UNION ALL

    SELECT fm.iter+1,
           fm.allergens || ARRAY[m.allergen],
           fm.ingredients || ARRAY[m.ingredient]
    FROM find_matches AS fm
    CROSS JOIN LATERAL (
        WITH RECURSIVE

        find_match AS (
            SELECT 0 AS iter,
                   allergen,
                   array_agg(DISTINCT id) AS ids,
                   array_agg(DISTINCT ingredient) AS ingredients
            FROM input
            WHERE allergen <> ALL (fm.allergens)
              AND ingredient <> ALL (fm.ingredients)
            GROUP BY allergen

            UNION ALL

            SELECT c.iter+1,
                   c.allergen,
                   c.ids[2:],
                   ARRAY (
                        SELECT ingredient
                        FROM unnest(c.ingredients) AS i (ingredient)
                        INTERSECT
                        SELECT ingredient
                        FROM input AS i
                        WHERE i.id = c.ids[1]
                          AND i.allergen = c.allergen
                   )
            FROM find_match AS c
            WHERE c.ids <> '{}'
        )

        SELECT allergen, ingredients[1]
        FROM find_match
        WHERE cardinality(ingredients) = 1
    ) AS m (allergen, ingredient)
)

SELECT count(*)
FROM (
    SELECT DISTINCT id, ingredient
    FROM input AS i
    CROSS JOIN LATERAL (
        SELECT ingredients
        FROM find_matches
        ORDER BY iter DESC
        FETCH FIRST ROW ONLY
    ) AS ingredients
    WHERE i.ingredient <> ALL (ingredients)
)_
;

/* SECOND STAR */

WITH RECURSIVE

input (id, ingredient, allergen) AS (
    SELECT line_number, ingredient, allergen
    FROM dec21,
         LATERAL regexp_match(line, '^([^(]+) \(contains (.+)\)$') AS m,
         LATERAL regexp_split_to_table(m[1], ' ') AS ingredient,
         LATERAL regexp_split_to_table(m[2], ', ') AS allergen
),

find_matches (iter, allergens, ingredients) AS (
    VALUES (0, CAST(ARRAY[] AS text[]), CAST(ARRAY[] AS text[]))

    UNION ALL

    SELECT fm.iter+1,
           fm.allergens || ARRAY[m.allergen],
           fm.ingredients || ARRAY[m.ingredient]
    FROM find_matches AS fm
    CROSS JOIN LATERAL (
        WITH RECURSIVE

        find_match AS (
            SELECT 0 AS iter,
                   allergen,
                   array_agg(DISTINCT id) AS ids,
                   array_agg(DISTINCT ingredient) AS ingredients
            FROM input
            WHERE allergen <> ALL (fm.allergens)
              AND ingredient <> ALL (fm.ingredients)
            GROUP BY allergen

            UNION ALL

            SELECT c.iter+1,
                   c.allergen,
                   c.ids[2:],
                   ARRAY (
                        SELECT ingredient
                        FROM unnest(c.ingredients) AS i (ingredient)
                        INTERSECT
                        SELECT ingredient
                        FROM input AS i
                        WHERE i.id = c.ids[1]
                          AND i.allergen = c.allergen
                   )
            FROM find_match AS c
            WHERE c.ids <> '{}'
        )

        SELECT allergen, ingredients[1]
        FROM find_match
        WHERE cardinality(ingredients) = 1
    ) AS m (allergen, ingredient)
)

SELECT string_agg(ingredient, ',' ORDER BY allergen)
FROM (
    SELECT ingredients, allergens
    FROM find_matches
    ORDER BY iter DESC
    FETCH FIRST ROW ONLY
) AS fm
CROSS JOIN LATERAL unnest(ingredients, allergens) AS u (ingredient, allergen)
;
