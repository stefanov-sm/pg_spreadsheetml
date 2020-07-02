--------------------------------------------------
-- pg_spreadsheetml helpers, S. Stefanov, Feb-2020
--------------------------------------------------

/**
  * Performs tag escaping.
  *
  * Example:
    testdb=> select xml_escape( '<xml version="1.0"> <equation> 10 > 20 && 20 < 100 </equation> </xml>' );
                                                   xml_escape
  -------------------------------------------------------------------------------------------------------------
   &lt;xml version="1.0"&gt; &lt;equation&gt; 10 &gt; 20 &amp;&amp; 20 &lt; 100 &lt;/equation&gt; &lt;/xml&gt;
  (1 row)
*/
create or replace function xml_escape(s text)
returns text language sql immutable strict as
$$
    select  regexp_replace( regexp_replace( regexp_replace( s, '&', '&amp;', 'g' )
                                , '>'
                                , '&gt;'
                                , 'g' )
                            , '<'
                            , '&lt;'
                            , 'g' );
$$;

create or replace function public.json_typeofx(j json)
returns text language sql immutable AS
$$
select
  case
    when json_typeof(j) = 'string' then case 
      when j::text ~ '^"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?' then 'datetime'
      when j::text ~ '^"\d{4}-\d\d-\d\d' then 'date'
      when j::text ~ '^"#.+##.+' then 'href'
      else 'string' 
    end
    else json_typeof(j)
  end;
$$;

/**
  * Performs macro expansion.
  * A macro is any text with a double underscore at the beginning and at the end,
  * like for example __FOO__.
  * Macros are globally substituted with values into the `args` json array.
  *
  * Example:
  testdb=> SELECT macro_expand( 'SELECT __FOO__ FROM __bar__ WHERE __i__ like __I__',
                                '{ "I" : "10", "j" : "20", "bar" : "30", "foo" : "40" }'::json );
              macro_expand
  ------------------------------------
   SELECT 40 FROM 30 WHERE 10 like 10




  testdb=> SELECT macro_expand( 'SELECT __FOO__ FROM __bar__ WHERE __i__ like __I__ AND __Z__ = 99',
                                '{ "I" : "10", "j" : "20", "bar" : "30", "foo" : "40" }'::json );
  ERROR:  1 macro(s) not expanded, please check your JSON arguments!

  */
create or replace function macro_expand(macro text, args json)
returns text language plpgsql immutable strict as
$$
declare
  k text;
  v text;
  macro_to_expand text[];
  hint_message text;
begin
  for k, v in select "key", "value" from json_each_text(args) loop
    macro := regexp_replace( macro
                              , '__'|| k ||'__'
                              , coalesce( v, '' )
                              , 'gi' );
    raise debug 'Key [%] = [%] produced [%]', k, v, macro;
  end loop;

  -- check there is no macro without expansion
  macro_to_expand := ARRAY( SELECT regexp_matches( macro, '__[a-z]+__',  'gi' ) );
  if array_length( macro_to_expand, 1 ) > 0 then
    hint_message := 'Macro(s) left: ' ||  array_to_string( macro_to_expand, ', ' );
    raise exception '% macro(s) not expanded, please check your JSON arguments!'
                  , array_length( macro_to_expand, 1 )
             using hint = hint_message;
  end if;

  return macro;
end;
$$;
