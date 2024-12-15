## Search using ilike function in Postgres

### LIKE function

Differs from ilike function in case-sensitivity, ILIKE is case-insensitive, but is not sql standard function.

'abc' LIKE 'abc' true
'abc' LIKE 'a%' true
'abc' LIKE '_b_' true
'abc' LIKE 'c' false

IF we want to search for a pattern inside a string then we need to put % sign before and after the pattern.

```sql

```
