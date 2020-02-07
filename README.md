# pg_spreadsheetml
Export SQL query results to Excel  
pl/pgsql function returns SpreadsheetML (XML format for storing Excel spreadsheets ) as **setof text**. 

```PGSQL
FUNCTION public.pg_spreadsheetml(arg_query text, arg_parameters json DEFAULT '{}'::json)
 RETURNS SETOF text
 LANGUAGE plpgsql SECURITY DEFINER
```
### Notes
__arg_query__ is parameterised by plain text susbtitution (macro expansion).  
Macro parameters are defined as valid uppercase identifiers with two underscores as prefix and suffix, i.e. `__CAR_COLOR__`, `__SALARY__`, etc.

Optional __arg_parameters__ is JSON with parameters' names/values, i.e. `{"car_color":"graphite", "salary":1000}`. Parameters' names are case-insensitive.

pg_spreadsheetml is __injection prone__ and therefore it must be declared as a security definer owned by a limited user.

The example runs against the popular [DVD rental](https://www.postgresqltutorial.com/postgresql-sample-database/) sample database.
