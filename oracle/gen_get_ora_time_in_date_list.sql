--
-- Check DATE columns, if they contain time portion on Oracle
-- This is done by counting distinct time value of each column
-- The count of 1 means, that all rows have the same time value
-- What is usually 00:00:00 (no time included) but is not guaranteed
--

set feed off verify off pause off arraysize 1 num 2
set echo off pages 0 lines 1000 term off hea off trimspool on trim on
set colsep " "

undef EIGENTUEMER
col TAB_O new_value EIGENTUEMER

select
     upper('&1') TAB_O
from dual;

column X1 noprint
column X2 noprint
column X3 noprint
column X4 noprint

spool get_ora_time_in_date_list.sql
prompt set colsep "	"
prompt column CON for 99990
prompt spool ora_time_in_data_list.txt
select
    OWNER         X1
    ,TABLE_NAME   X2
    ,0            X3
    ,0            X4
    ,'select ''' || OWNER || '  ' || TABLE_NAME || ''''
from    ALL_TAB_COLUMNS, (select max(COLUMN_ID) MAXCOL, min(COLUMN_ID) MINCOL
                from ALL_TAB_COLUMNS where OWNER = '&EIGENTUEMER' and DATA_TYPE = 'DATE') B
where   OWNER = '&EIGENTUEMER'
and DATA_TYPE = 'DATE'
union all
select
    OWNER         X1
    ,TABLE_NAME   X2
    ,1            X3
    ,COLUMN_ID    X4
    ,'  ,''' || COLUMN_NAME || ''', count(distinct(to_char(' || COLUMN_NAME || ', ''HH24:MI:SS''))) as CON'
from    ALL_TAB_COLUMNS, (select max(COLUMN_ID) MAXCOL, min(COLUMN_ID) MINCOL
                from ALL_TAB_COLUMNS where OWNER = '&EIGENTUEMER' and DATA_TYPE = 'DATE') B
where   OWNER = '&EIGENTUEMER'
and DATA_TYPE = 'DATE'
union all
select
    OWNER         X1
    ,TABLE_NAME   X2
    ,2            X3
    ,0            X4
    ,'from ' || OWNER || '.' || TABLE_NAME || ';'
from    ALL_TAB_COLUMNS, (select max(COLUMN_ID) MAXCOL, min(COLUMN_ID) MINCOL
                from ALL_TAB_COLUMNS where OWNER = '&EIGENTUEMER' and DATA_TYPE = 'DATE') B
where   OWNER = '&EIGENTUEMER'
and DATA_TYPE = 'DATE'
order by X1, X2, X3
;
prompt spool off
prompt set colsep " "
spool off
