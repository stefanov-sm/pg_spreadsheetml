--------------------------------------------------
-- pg_spreadsheetml, S. Stefanov, Feb-2020
--------------------------------------------------

-- helpers
--------------------------------------------------

CREATE OR REPLACE FUNCTION public.xml_escape(s text) RETURNS text LANGUAGE sql IMMUTABLE STRICT AS
$function$
  select replace(replace(replace(s, '&', '&amp;'), '>', '&gt;'), '<', '&lt;');
$function$;

--------------------------------------------------

CREATE OR REPLACE FUNCTION public.macro_expand(macro text, args json) RETURNS text LANGUAGE plpgsql IMMUTABLE STRICT AS
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

CREATE OR REPLACE FUNCTION public.json_typeofx(j json) RETURNS text LANGUAGE sql IMMUTABLE AS
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

--------------------------------------------------
-- helpers end

CREATE OR REPLACE FUNCTION public.pg_spreadsheetml(arg_query text, arg_parameters json DEFAULT '{}'::json)
RETURNS SETOF text LANGUAGE plpgsql SECURITY DEFINER AS
$function$
declare
WORKBOOK_HEADER constant text :=
$WORKBOOK_HEADER$<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
 <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office" />
 <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office" />
 <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel" />
 <Styles>
  <Style ss:ID="Default" ss:Name="Normal">
   <Font ss:FontName="Arial" ss:Size="10" ss:Color="#000000"/>
  </Style>
  <Style ss:ID="Date">
   <NumberFormat ss:Format="Short Date"/>
  </Style>
  <Style ss:ID="DateTime">
   <NumberFormat ss:Format="yyyy\-mm\-dd\ hh:mm\.ss"/>
  </Style>
  <Style ss:ID="Header">
   <Borders>
    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
    <Border ss:Position="Top"    ss:LineStyle="Continuous" ss:Weight="1"/>
    <Border ss:Position="Left"   ss:LineStyle="Continuous" ss:Weight="1"/>
    <Border ss:Position="Right"  ss:LineStyle="Continuous" ss:Weight="1"/>
   </Borders>
   <Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>
  </Style>
 </Styles>
 <Worksheet ss:Name="Sheet">
  <Table>$WORKBOOK_HEADER$;

WORKBOOK_FOOTER constant text :=
$WORKBOOK_FOOTER$  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <FreezePanes/><FrozenNoSplit/><SplitHorizontal>1</SplitHorizontal>
   <TopRowBottomPane>1</TopRowBottomPane><ActivePane>2</ActivePane>
  </WorksheetOptions>
</Worksheet>
</Workbook>$WORKBOOK_FOOTER$;

TITLE_ITEM    constant text := '    <Cell ss:StyleID="Header"><Data ss:Type="String">__VALUE__</Data></Cell>';
DATE_ITEM     constant text := '    <Cell ss:StyleID="Date"><Data ss:Type="DateTime">__VALUE__</Data></Cell>';
DTIME_ITEM    constant text := '    <Cell ss:StyleID="DateTime"><Data ss:Type="DateTime">__VALUE__</Data></Cell>';
TEXT_ITEM     constant text := '    <Cell><Data ss:Type="String">__VALUE__</Data></Cell>';
NUMBER_ITEM   constant text := '    <Cell><Data ss:Type="Number">__VALUE__</Data></Cell>';
COLUMN_ITEM   constant text := '   <Column ss:AutoFitWidth="0" ss:Width="__VALUE__"/>';
BEGIN_ROW     constant text := '   <Row>';
END_ROW       constant text := '   </Row>';
SR_TOKEN      constant text := '__VALUE__';

AVG_CHARWIDTH constant integer := 6;
MIN_FLDWIDTH  constant integer := 30;

r record;
jr json;
v_key text;
v_value text;
column_types text[];
running_line text;
running_column integer;
cold boolean := true;

begin
    return next WORKBOOK_HEADER;
    for r in execute macro_expand(arg_query, arg_parameters) loop

        jr := to_json(r);
        if cold then
            column_types := (select array_agg(json_typeofx(value)) from json_each(jr) jt);
            for v_key in select "key" from json_each_text(jr) jt loop
                running_line := replace(COLUMN_ITEM, SR_TOKEN, greatest(length(v_key) * AVG_CHARWIDTH, MIN_FLDWIDTH)::text);
                return next running_line;
            end loop;
            return next BEGIN_ROW;
            for v_key in select "key" from json_each_text(jr) jt loop
                running_line := replace(TITLE_ITEM, SR_TOKEN, xml_escape(v_key));
                return next running_line;
            end loop;
            return next END_ROW;
            cold := false;
        end if;

        return next BEGIN_ROW;
        running_column := 1;

        for v_key, v_value in select "key", value from json_each_text(jr) jt loop
        	v_value := coalesce(xml_escape(v_value), '');
            if column_types[running_column] = 'null' then
                column_types[running_column] := json_typeofx(jr -> v_key);
            end if;
            case column_types[running_column]
                when 'string', 'null' then running_line := replace(TEXT_ITEM,   SR_TOKEN, v_value);
                when 'number'         then running_line := replace(NUMBER_ITEM, SR_TOKEN, v_value);
                when 'boolean'        then running_line := replace(NUMBER_ITEM, SR_TOKEN, case when v_value = 'true' then 1 else 0 end);
                when 'date'           then running_line := replace(DATE_ITEM,   SR_TOKEN, v_value);
                when 'datetime'       then running_line := replace(DTIME_ITEM,  SR_TOKEN, v_value);
                else                       running_line := replace(TEXT_ITEM,   SR_TOKEN, v_value);
            end case;
            return next running_line;
            running_column := running_column + 1;

        end loop;
        return next END_ROW;
    end loop;
    return next WORKBOOK_FOOTER;
end;
$function$;

