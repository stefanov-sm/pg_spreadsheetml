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

create or replace function macro_expand(macro text, args json)
returns text language plpgsql immutable strict as
$$
declare
  k text;
  v text;
begin
  for k, v in select "key", "value" from json_each_text(args) loop
    macro := replace(macro, '__'||upper(k)||'__', coalesce(v, ''));
  end loop;
  return macro;
end;
$$;
