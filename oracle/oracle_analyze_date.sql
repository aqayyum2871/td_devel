-- (c) 2012 by Teradata Germany GesmbH, Andreas Wenzel
--
-- Dynamic SQL to generate list of SQLs for analyzing date fields if the time
-- portion is included or not!
-- Script is for Oracle SQL*Plus
-- Two arguments on invocation required
--  1. Owner for the database (like notation allowed)
--  2. Spool file name and path

set time off timing off echo off feed off verify off pages 0 trim on trimspool on linesize 500 term off

spool &2
select 'set term off feed off head on echo off pages 15 lines 2000 verify off' from dual;
select 'spool tmp_oracle_analyze_date_result.txt' from dual;
select 'col database_name for a30' from dual;
select 'col table_name for a30' from dual;
select
	sql_text
from (
	select
		t01.owner as table_owner
		,t01.table_name
		,1 as pos1
		,1 as pos2
		,'--##--##--##	'||t01.owner||'	'||t01.table_name as sql_text
	from
		all_tables t01
		,all_tab_columns t02
	where t01.owner = t02.owner
	and t01.table_name = t02.table_name
	and t01.nested = 'NO'
	and t02.DATA_TYPE = 'DATE'
	union
	select
		t01.owner as table_owner
		,t01.table_name
		,10 as pos1
		,1 as pos2
		,'select '''||t01.owner||''' as database_name, '''||t02.table_name||'''as table_name, count(*) as all_count' as sql_text
	from
		all_tables t01
		,all_tab_columns t02
	where t01.owner = t02.owner
	and t01.table_name = t02.table_name
	and t01.nested = 'NO'
	and t02.DATA_TYPE = 'DATE'
	union
	select
		t01.owner
		,t01.table_name
		,20 as pos1
		,t02.column_id as pos2
		,'	,count(distinct to_char(nvl('||t02.column_name||', trunc(sysdate)), ''HH24:MI:SS'')) as COL_'||t02.column_name as sql_text
	from
		all_tables t01
		,all_tab_columns t02
	where t01.owner = t02.owner
	and t01.table_name = t02.table_name
	and t01.nested = 'NO'
	and t02.DATA_TYPE = 'DATE'
	union
	select
		t01.owner
		,t01.table_name
		,30 as pos1
		,1 as pos2
		,'from '||t01.owner||'.'||t01.table_name as sql_text
	from
		all_tables t01
		,all_tab_columns t02
	where t01.owner = t02.owner
	and t01.table_name = t02.table_name
	and t01.nested = 'NO'
	and t02.DATA_TYPE = 'DATE'
	union
	select
		t01.owner
		,t01.table_name
		,40 as pos1
		,1 as pos2
		,decode(t01.partitioned, 'NO', '/', 'sample(10);') as sql_text
	from
		all_tables t01
		,all_tab_columns t02
	where t01.owner = t02.owner
	and t01.table_name = t02.table_name
	and t01.nested = 'NO'
	and t02.DATA_TYPE = 'DATE'
	) all_of_it
where table_owner like upper('&1')
order by table_owner, table_name, pos1, pos2
/
select '--##--##--##	END' from dual;
select 'spool off' from dual;
spool off
