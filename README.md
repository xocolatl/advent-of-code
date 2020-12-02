This is my attempt to solve the [Advent Of Code 2020](http://adventofcode.com/2020)
puzzles using [PostgreSQL 13](https://www.postgresql.org/). I don't plan to use
any extensions except for what comes in contrib. I'm also going to try to avoid
using plpgsql (and certainly any other pl).

The goal is to challenge my SQL skills, and also showcase what can be done in this
language.

**Comments and improvements welcome.**

If you would like to run these yourself, save your session cookie in a file called
`session.cookie` at the top of this repository. In it, add the line
`Set-Cookie: session=1234` (where 1234 is replaced by what the site gives you after
logging in). Then run `psql -Xqf 2020/decXX.sql`.

  - <http://adventofcode.com/2020> :christmas\_tree:
  - <https://www.postgresql.org/> :elephant:
