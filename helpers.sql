--------------------------------------------------
-- pg_spreadsheetml helpers, S. Stefanov, Feb-2020
--------------------------------------------------

create or replace function xml_escape(s text)
returns text language sql immutable strict as
$$
  select replace(replace(replace(s, '&', '&amp;'), '>', '&gt;'), '<', '&lt;');
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

  */
create or replace function macro_expand(macro text, args json)
returns text language plpgsql immutable strict as
$$
declare
  k text;
  v text;
begin
  for k, v in select "key", "value" from json_each_text(args) loop
    macro := regexp_replace( macro
                              , '__'|| k ||'__'
                              , coalesce( v, '' )
                              , 'gi' );
    raise debug 'Key [%] = [%] produced [%]', k, v, macro;
  end loop;
  return macro;
end;
$$;
