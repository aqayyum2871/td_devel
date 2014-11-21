--
-- Select table information and column information (for import into Excel)
-- change WHERE condition of databasename
--

select trim(t01.TableName) TableName
	,case when t01.CheckOpt = 'N' then 'SET' when t01.CheckOpt = 'Y' then 'MULTISET' end TableType
	,case when t01.Commentstring is null then '' else trim(t01.CommentString) end CommentString
	,case when t01.TableKind = 'O' then 'yes' else '' end "no PI Table"
	,case when t02.IndexName is null then '' else t02.Indexname end PI_Name
from dbc.tables t01
left join (select databasename, tablename, IndexName from dbc.indices where indextype = 'P' group by databasename, tablename, IndexName) t02
on t01.databasename = t02.databasename
and t01.tablename = t02.tablename
where t01.databasename = 'STG_CDE_01';

-- Does not support PPI at the moment
-- Still some datatypes missing
select trim(t01.TableName) TableName
	,trim(t03.ColumnName) ColumnName
	,row_number() over (partition by t01.databasename, t01.tablename order by t03.ColumnId) "Pos"
	,'' PrimaryKey
	,case when t02.ColumnName is not null and t02.UniqueFlag = 'N' then 'NUPI'
	      when t02.ColumnName is not null and t02.UniqueFlag = 'Y' then 'UPI'
	      else ''
	 end "PI"
	,'' "PPI"
	,t03.ColumnType "Datatype ori"
	,case when t03.ColumnType = 'DA' then 'DATE'
	      when t03.ColumnType = 'AT' and t03.ColumnLength = 8 then 'TIME(0)'
	      when t03.ColumnType = 'AT' and t03.ColumnLength > 8 then 'TIME('||trim(t03.ColumnLength-9)||')'
	      when t03.ColumnType = 'TS' and t03.ColumnLength = 19 then 'TIMESTAMP(0)'
	      when t03.ColumnType = 'TS' and t03.ColumnLength > 19 then 'TIMESTAMP('||trim(t03.ColumnLength-20)||')'
	      when t03.ColumnType = 'CF' then 'CHAR'||'('||trim(t03.ColumnLength)||')'
	      when t03.ColumnType = 'CV' then 'VARCHAR'||'('||trim(t03.ColumnLength)||')'
	      when t03.ColumnType = 'I'  then 'INTEGER'
	      when t03.ColumnType = 'I1' then 'BYTEINT'
	      when t03.ColumnType = 'I2' then 'SMALLINT'
	      when t03.ColumnType = 'I8' then 'BIGINT'
	      when t03.ColumnType = 'D' and t03.DecimalTotalDigits is not null and t03.DecimalFractionalDigits is not null then 'DECIMAL('||trim(t03.DecimalTotalDigits)||','||trim(t03.DecimalFractionalDigits)||')'
	 end "Datatype TD"
	,'' as "CharacterSet"
	,'' as "Casespecific"
	,case when t03.Nullable = 'N' then 'yes' else 'no' end "Required"
	,case when t03.ColumnType = 'DA' then t03.ColumnFormat else '' end "Format"
	,case when t03.DefaultValue is null then '' else t03.DefaultValue end "Default Value"
	,case when t03.CommentString is null then '' else t03.CommentString end "Comment"
	,'' "Synthethic by DWH"
	,'' "PPI Definition"
from dbc.tables t01
join dbc.columns t03
on t01.databasename = t03.databasename
and t01.tablename = t03.tablename
left join dbc.indices t02
on t01.databasename = t02.databasename
and t01.tablename = t02.tablename
and t02.IndexType = 'P'
and t02.columnname = t03.columnname
where t01.databasename = 'STG_CDE_01'
order by t01.TableName, t03.ColumnId;
