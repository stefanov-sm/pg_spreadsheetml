# pg_spreadsheetml
Exports an SQL query result into Microsoft Excel format.  
pl/pgsql function returns [SpreadsheetML](https://en.wikipedia.org/wiki/Microsoft_Office_XML_formats) (XML format for storing Microsoft Excel spreadsheets) as **setof text**. 


The prototype of the function is as follows:

```PGSQL
FUNCTION pg_spreadsheetml(arg_query text, arg_parameters json DEFAULT '{}'::json)
 RETURNS SETOF text
 LANGUAGE plpgsql SECURITY DEFINER
```
__arg_query__ is parameterised by plain text susbtitution (macro expansion).  
Macro parameter placeholders are defined as valid uppercase identifiers with two underscores as prefix and suffix, i.e. `__NUMBER_OF_DAYS__`, `__COST__`, etc. See the [example](https://github.com/stefanov-sm/pg_spreadsheetml/tree/master/example) SQL-only and PHP CLI scripts.

Optional __arg_parameters__ is JSON with parameters' names/values, e.g., 
`{"number_of_days":"7 days", "cost":15.00}`. 
Parameter names are K&R case-insensitive identifiers.  

__Hyperlinks:__ Cell values that match this regex pattern `^#(.+)##(.+)$`, i.e. #_value_##_URL_ will be presented as hyperlinks.  

__Note:__ pg_spreadsheetml is __injection prone__ and therefore it must be declared as a security definer owned by a limited user.


__Note:__ The example runs against the popular [DVD rental](https://www.postgresqltutorial.com/postgresql-sample-database/) sample database.
