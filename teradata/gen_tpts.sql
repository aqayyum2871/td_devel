.logon bla/bla,bla

.set width 500

create volatile table TPT_Loader_Script_Owner (
	Table_Owner       varchar(100) not null
	,Loader_Type      varchar(20) not null
	,Max_Sessions     integer not null
	,TDPID            varchar(50) not null
	,Logon_User       varchar(50) not null
	,Logon_PWD        varchar(50) not null
	,Directory_Path   varchar(200) not null
	,DB_Log_Table     varchar(100) not null
	,Character_Set    varchar(20) not null
	) unique primary index (Table_Owner) on commit preserve rows;
.if errorcode <> 0 then .quit errorcode

create volatile table TPT_Loader_Scripts (
	Table_Owner   varchar(500) not null
	,Table_Name   varchar(500) not null
	,POS1         integer not null
	,POS2         integer not null
	,TPT_Text     varchar(6000)
) primary index (Table_Owner, Table_Name) on commit preserve rows;
.if errorcode <> 0 then .quit errorcode

insert into TPT_Loader_Script_Owner values ('DB1', 'LOAD', 1, '@TDPID', '@UserName', '@UserPassword', '.', 'DB_TMP', 'UTF8')
;insert into TPT_Loader_Script_Owner values ('DB2', 'LOAD', 1, '@TDPID', '@UserName', '@UserPassword', '.', 'DB_TMP', 'UTF8')
.if errorcode <> 0 then .quit errorcode

.run file = gen_tpt.sql

.os rm tmp/gen_tpt_scripts.sql

.export report file = tmp/gen_tpt_scripts.sql
select MyText (title '')
from (
		select Table_Owner, Table_Name, cast(10 as smallint) Pos, '.os rm tpt/'||trim(Table_Owner)||'/'||trim(Table_Owner)||'.'||trim(Table_Name)||'.tpt' (varchar(500)) as MyText
		from TPT_Loader_Scripts
		where (Table_Owner, Table_Name) not in (select databasename, tablename from dbc.columns where columntype in ('CO', 'BO') group by databasename, tablename)
		group by Table_Owner, Table_Name
		union all
		select Table_Owner, Table_Name, cast(20 as smallint) Pos, '.export report file = tpt/'||trim(Table_Owner)||'/'||trim(Table_Owner)||'.'||trim(Table_Name)||'.tpt'
		from TPT_Loader_Scripts
		where (Table_Owner, Table_Name) not in (select databasename, tablename from dbc.columns where columntype in ('CO', 'BO') group by databasename, tablename)
		group by Table_Owner, Table_Name
		union all
		select Table_Owner, Table_Name, cast(30 as smallint) Pos, 'select TPT_Text (title '''') from TPT_Loader_Scripts where Table_Owner = '''||trim(Table_Owner)||''' and Table_Name = '''||trim(Table_Name)||''' order by POS1, POS2;'
		from TPT_Loader_Scripts
		where (Table_Owner, Table_Name) not in (select databasename, tablename from dbc.columns where columntype in ('CO', 'BO') group by databasename, tablename)
		group by Table_Owner, Table_Name
		union all
		select Table_Owner, Table_Name, cast(40 as smallint) Pos, '.export reset'
		from TPT_Loader_Scripts
		where (Table_Owner, Table_Name) not in (select databasename, tablename from dbc.columns where columntype in ('CO', 'BO') group by databasename, tablename)
		group by Table_Owner, Table_Name
	) x01
order by Table_Owner, Table_Name, Pos
;
.if errorcode <> 0 then .quit errorcode
.export reset

.run file = tmp/gen_tpt_scripts.sql

.quit 0
