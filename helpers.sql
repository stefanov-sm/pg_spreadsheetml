--------------------------------------------------
-- pg_spreadsheetml helpers, S. Stefanov, Feb-2020
--------------------------------------------------

CREATE OR REPLACE FUNCTION xml_escape(s text)
RETURNS text LANGUAGE sql IMMUTABLE STRICT AS
$function$
  select replace(replace(replace(s, '&', '&amp;'), '>', '&gt;'), '<', '&lt;');
$function$;
--------------------------------------------------

CREATE OR REPLACE FUNCTION macro_expand(macro text, args json)
RETURNS text LANGUAGE plpgsql IMMUTABLE STRICT AS
$function$
declare
    k text;
    v text;
begin
    for k, v in select "key", "value" from json_each_text(args) loop
        macro := replace(macro, '__' || upper(k) || '__', coalesce(v, ''));
    end loop;
    return macro;
end;
$function$;
--------------------------------------------------

CREATE OR REPLACE FUNCTION json_typeofx(j json)
RETURNS text LANGUAGE sql IMMUTABLE AS
$function$
select
  case
    when json_typeof(j) = 'string' then case 
      when j::text ~ '^"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?' then 'datetime'
      when j::text ~ '^"\d{4}-\d\d-\d\d' then 'date'
      else 'string' 
    end
    else json_typeof(j)
  end;
$function$;
