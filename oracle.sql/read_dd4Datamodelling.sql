set pages 0 echo off feed off verify off trim on trimspool on lines 4000 term off

-- get table definitions
spool tables.txt
select t01.owner||'	'||t01.table_name||'	'||to_char(null)||'	'||'MULTISET'||'	'||translate(t02.comments, chr(10)||chr(13)||chr(8)||chr(9), '    ')||'	'||to_char(null)||'	'||to_char(null)
from all_tables t01
left join all_tab_comments t02
on t01.owner = t02.owner
and t01.table_name = t02.table_name
where t01.owner in (<SCHEMALIST>)
and t01.nested = 'NO'
and (t01.iot_type is null or t01.iot_type = 'IOT')
order by t01.table_name;
spool off

-- get column definitions
spool columns.txt
select
	owner||'	'||
	table_name||'	'||
	column_name||'	'||
	"Pos"||'	'||
	"ColNameLen"||'	'||
	"reserved word?"||'	'||
	PK||'	'||
	UK1||'	'||
	UK2||'	'||
	UK3||'	'||
	UK4||'	'||
	UK5||'	'||
	"PI"||'	'||
	"PPI"||'	'||
	"SCS"||'	'||
--	data_type||'	'||
	"Datatype SRC"||'	'||
	"Datatype TD"||'	'||
	"Characterset"||'	'||
	"Casespecific"||'	'||
	"Required"||'	'||
	"Format"||'	'||
	"Default Value"||'	'||
	"Comment"
from (
		select
			t01.owner
			,t01.table_name
			,t02.column_name
			,t02.column_id
			,row_number() over (partition by t02.table_name order by column_id) "Pos"
			,to_char(null) "ColNameLen"
			,to_char(null) "reserved word?"
			,t06.PK
			,t07.UK1
			,t07.UK2
			,t07.UK3
			,t07.UK4
			,t07.UK5
			,decode(t06.PK, 'x', 'UPI') "PI"
			,to_char(null) "PPI"
			,to_char(null) "SCS"
			,t02.data_type
			,case
				when t02.data_type = 'NUMBER' and t02.data_precision is null and t02.data_scale is null then 'NUMBER'
				when t02.data_type = 'NUMBER' and t02.data_precision is null and t02.data_scale = 0 then 'NUMBER'
				when t02.data_type = 'NUMBER' and t02.data_precision is not null and t02.data_scale = 0 then 'NUMBER('||to_char(t02.data_precision)||')'
				when t02.data_type = 'NUMBER' and t02.data_precision is not null and t02.data_scale is not null then 'NUMBER('||to_char(t02.data_precision)||','||to_char(t02.data_scale)||')'
				when t02.data_type = 'VARCHAR2' then 'VARCHAR2('||to_char(t02.data_length)||')'
				when t02.data_type = 'CHAR' then 'CHAR('||to_char(t02.data_length)||')'
				when t02.data_type = 'NVARCHAR2' then 'VARCHAR2('||to_char(t02.data_length)||')'
				when t02.data_type = 'NCHAR' then 'CHAR('||to_char(t02.data_length)||')'
				else t02.data_type
			 end "Datatype SRC"
			,case
				when t02.data_type = 'DATE' then 'TIMESTAMP(0)'
				when t02.data_type = 'NUMBER' and t02.data_precision is null and t02.data_scale is null then 'NUMBER'
				when t02.data_type = 'NUMBER' and t02.data_precision is null and t02.data_scale = 0 then 'NUMBER'
				when t02.data_type = 'NUMBER' and t02.data_precision is not null and t02.data_scale = 0 then 'NUMBER('||to_char(t02.data_precision)||')'
				when t02.data_type = 'NUMBER' and t02.data_precision is not null and t02.data_scale is not null then 'NUMBER('||to_char(t02.data_precision)||','||to_char(t02.data_scale)||')'
				when t02.data_type = 'VARCHAR2' then 'VARCHAR('||to_char(t02.data_length)||')'
				when t02.data_type = 'CHAR' then 'CHAR('||to_char(t02.data_length)||')'
				when t02.data_type = 'NVARCHAR2' then 'VARCHAR('||to_char(t02.data_length)||')'
				when t02.data_type = 'NCHAR' then 'CHAR('||to_char(t02.data_length)||')'
				when t02.data_type = 'RAW' then 'RAW'
				when t02.data_type = 'BLOB' then 'BLOB'
				when t02.data_type = 'CLOB' then 'CLOB'
				when t02.data_type = 'ROWID' then 'ROWID'
				when t02.data_type = 'XMLTYPE' then 'XMLTYPE'
				else t02.data_type
			 end "Datatype TD"
			,case
				when t02.data_type = 'VARCHAR2' then 'latin'
				when t02.data_type = 'CHAR' then 'latin'
				when t02.data_type = 'NVARCHAR2' then 'unicode'
				when t02.data_type = 'NCHAR' then 'unicode'
			 end "Characterset"
			,case
				when t02.data_type = 'VARCHAR2' then 'not casespecific'
				when t02.data_type = 'CHAR' then 'not casespecific'
				when t02.data_type = 'NVARCHAR2' then 'not casespecific'
				when t02.data_type = 'NCHAR' then 'not casespecific'
			 end "Casespecific"
			,case
				when t02.nullable = 'N' then 'yes'
				when t02.nullable = 'Y' then 'no'
			 end "Required"
			,case
				when t02.data_type = 'DATE' then 'YYYY-MM-DD'
				when t02.data_type = 'TIMESTAMP' and (t02.data_scale is null or t02.data_scale = 0) then 'YYYY-MM-DD HH:MI:SS'
			 end "Format"
			,null "Default Value"
			,translate(t03.comments, chr(10)||chr(13)||chr(8)||chr(9), '    ') "Comment"
			,to_char(null) "Min Value"
			,to_char(null) "Max Value"
			,to_char(null) "Synthetic by DWH"
			,to_char(null) "Generate Table"
		from all_tables t01
		join all_tab_columns t02
		on t01.owner = t02.owner
		and t01.table_name = t02.table_name
		join all_col_comments t03
		on t02.owner = t03.owner
		and t02.table_name = t03.table_name
		and t02.column_name = t03.column_name
		left join
			(
				select t11.owner, t11.table_name, t12.column_name, 'x' as PK
				from all_constraints t11
				join all_cons_columns t12
				on T11.OWNER = T12.OWNER
				and T11.CONSTRAINT_NAME = T12.CONSTRAINT_NAME
				where t11.constraint_type = 'P'
				and t11.owner in (<SCHEMALIST>)
				group by t11.owner, t11.table_name, t12.column_name
			) t06
		on t02.owner = t06.owner
		and t02.table_name = t06.table_name
		and t02.column_name = t06.column_name
		left join
			(
				select t31.TABLE_OWNER, t31.TABLE_NAME, t31.COLUMN_NAME, min(t31.UK1) UK1, min(t31.UK2) UK2, min(t31.UK3) UK3, min(t31.UK4) UK4, min(t31.UK5) UK5
				from
					(
						select T21.TABLE_OWNER, T21.TABLE_NAME, T22.COLUMN_NAME, decode(row_number() over (partition by T21.TABLE_OWNER, T21.TABLE_NAME, T22.COLUMN_NAME order by t21.INDEX_NAME), 1, 'x') UK1, decode(row_number() over (partition by T21.TABLE_OWNER, T21.TABLE_NAME, T22.COLUMN_NAME order by t21.INDEX_NAME), 2, 'x') UK2, decode(row_number() over (partition by T21.TABLE_OWNER, T21.TABLE_NAME, T22.COLUMN_NAME order by t21.INDEX_NAME), 3, 'x') UK3, decode(row_number() over (partition by T21.TABLE_OWNER, T21.TABLE_NAME, T22.COLUMN_NAME order by t21.INDEX_NAME), 4, 'x') UK4, decode(row_number() over (partition by T21.TABLE_OWNER, T21.TABLE_NAME, T22.COLUMN_NAME order by t21.INDEX_NAME), 5, 'x') UK5
						from all_indexes t21
						join all_ind_columns t22
						on T21.OWNER = T22.INDEX_OWNER
						and T21.INDEX_NAME = T22.INDEX_NAME
						left join all_constraints t23
						on T22.INDEX_OWNER = nvl(T23.INDEX_OWNER, T23.OWNER)
						and t22.INDEX_NAME = T23.INDEX_NAME
						and T23.CONSTRAINT_TYPE = 'P'
						where T21.UNIQUENESS = 'UNIQUE'
						and T21.TABLE_OWNER in (<SCHEMALIST>)
						and T23.TABLE_NAME is null
					) t31
				group by t31.TABLE_OWNER, t31.TABLE_NAME, t31.COLUMN_NAME
			) t07
		on t02.owner = t07.table_owner
		and t02.table_name = t07.table_name
		and t02.column_name = t07.column_name
		where t01.owner in (<SCHEMALIST>)
		and t01.nested = 'NO'
		and (t01.iot_type is null or t01.iot_type = 'IOT')
	) x1
order by owner, table_name, column_id;
spool off
exit
