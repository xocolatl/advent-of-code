\set ON_ERROR_STOP true
CREATE TABLE dec01 (rownum bigint GENERATED ALWAYS AS IDENTITY, input bigint);

/* Import the input file.  We're using perl to remove the final newline. */
\COPY dec01 (input) FROM PROGRAM 'perl -pe ''chomp if eof'' input.dat'

\timing on

/* Part One is trivial in SQL */
SELECT sum(input)
FROM dec01;

/*
 * PostgreSQL does not (yet) optimize for tail recursion so we have to resort
 * to plpgsql to have any kind of space management.
 *
 * At first I did this the naive way by double looping and storing everything
 * seen in an array, but that took about three minutes.  Since we're not doing
 * pure SQL anyway, let's use a table so we can take advantage of a UNIQUE
 * btree index.  Unfortunately, that means we have to pattern match the error
 * message to get the value.
 *
 * This version executes in about half a second.
 */
DO LANGUAGE plpgsql
$$
DECLARE
    detail text;
    step CONSTANT bigint NOT NULL DEFAULT (SELECT sum(input) FROM dec01);
    i bigint NOT NULL DEFAULT 0;
BEGIN
    CREATE TEMPORARY TABLE freqs (freq bigint PRIMARY KEY);

    LOOP
        INSERT INTO freqs
            SELECT i + sum(input) OVER (ORDER BY rownum)
            FROM dec01
            ORDER BY rownum;
        i := i + step;
    END LOOP;
EXCEPTION
    /* How ugly is this, eh? */
    WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS detail = PG_EXCEPTION_DETAIL;
        RAISE NOTICE '%', substring(detail from 'Key \(freq\)=\((\d+)\) already exists.');
END;
$$;

/*
 * Wish list:
 *
 * -   Tail recursion optimization
 * -   Some sort of "set" type that can efficiently find a value
 *
 */
