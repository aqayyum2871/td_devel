-- Unload an Oracle table to flat file (delimitted)
-- Field delimitter can be chosen

-- (c) 1997-2014 by Teradata GesmbH

-- Execution (from SQL*plus):
-- Argument 1 = Tablenowner (case-insensitiv)
-- Argument 2 = Tablename (case-insensitiv), no View or Synonyms allowed
-- Argument 3 = define date columns (DT=unload date and time, D=unload date portion only)
-- Argument 4 = Target tablename (to load into)

-- This version cannot process unicode character set

-- #############################################################################
-- Delimiter for fields (CSV)
undef DELIMI
define DELIMI="	"

-- If the DELIMI is part of a data content, the DELIMI will be changed to DELIMI2
undef DELIMI2
define DELIMI2=|
-- DELIMI2 must be different from DELIMI
-- #############################################################################

-- New lines in data will be replace with this character
undef CRDELIMI
define CRDELIMI=°

--
-- Standard definitions
--

set feed off verify off pause off arraysize 1 num 2
set echo off pages 0 lines 300 term off hea off trim on trimspool on

column X1 noprint
column X2 noprint

undef TABELLE
undef NEU_TABELLE
undef DATFORM
undef DATFORM2
undef DATLEN
undef EIGENTUEMER
col DAT_FOR new_value DATFORM
col DAT_FOR2 new_value DATFORM2
col DAT_LEN new_value DATLEN
col TAB_N new_value TABELLE
col TAB_NNEU new_value NEU_TABELLE
col TAB_O new_value EIGENTUEMER

select decode(upper('&&3'),'DT','YYYYMMDDHH24MISS','YYYYMMDD') DAT_FOR,
       decode(upper('&3'),'DT','YYYYMMDDHHMISS','YYYYMMDD') DAT_FOR2,
       decode(upper('&3'),'DT','14','8') DAT_LEN,
       upper('&&2') TAB_N,
       upper('&&4') TAB_NNEU,
       upper('&&1') TAB_O
from dual;

--
-- Generation of Oracle-SQL*Loader-Parameter-File
--

spool &1-&2..par

select 'log=&1-&2..log' from dual;
prompt errors=9
select 'bad=&1-&2..bad' from dual;
select 'control=&1-&2..ctl' from dual;
select 'data=&1-&2..lst' from dual;
prompt direct=true

spool off

--
-- Generation of Oracle-SQL*Loader-Control-File
--

spool &1-&2..ctl

select 'load data into table &NEU_TABELLE' from dual;
select 'fields terminated by ''&DELIMI''' from dual;
prompt trailing nullcols (
select D.COLUMN_ID X1, D.DATA_TYPE X2,
  rpad(D.COLUMN_NAME, 30)||
  decode(substr(D.DATA_TYPE, 1, decode(instr(D.DATA_TYPE, '('), 0, length(D.DATA_TYPE), instr(D.DATA_TYPE, '(') -1)),
        'DATE', ' date '||'"'||'&DATFORM'||'"',
        'TIMESTAMP', ' timestamp "YYYYMMDDHH24MISSxFF"',
        null)||
  decode(D.NULLABLE, 'Y', ' nullif '||D.COLUMN_NAME||'=blanks', null)||','
from  (select A.COLUMN_ID, A.COLUMN_NAME, A.DATA_TYPE, A.NULLABLE,
        sum(nvl(decode(decode(B.DATA_TYPE,'NUMBER',
          decode(sign(nvl(B.DATA_PRECISION,0))+sign(B.DATA_SCALE),
            null,'FLOAT',0,'INT','FIXP'), substr(B.DATA_TYPE, 1, decode(instr(B.DATA_TYPE, '('), 0, length(B.DATA_TYPE), instr(B.DATA_TYPE, '(') -1))),
            'VARCHAR2', B.DATA_LENGTH+1,
            'CHAR', B.DATA_LENGTH+1,
            'DATE', &DATLEN+1,
            'TIMESTAMP', 15 + B.DATA_SCALE+1,
            'FLOAT', 49,
            'INT', 48,
            'FIXP', B.DATA_PRECISION+2+sign(nvl(B.DATA_SCALE,0)),
            null), 0)) SUM1,
        sum(nvl(decode(decode(C.DATA_TYPE,'NUMBER',
          decode(sign(nvl(C.DATA_PRECISION,0))+sign(C.DATA_SCALE),
            null,'FLOAT',0,'INT','FIXP'), substr(C.DATA_TYPE, 1, decode(instr(C.DATA_TYPE, '('), 0, length(C.DATA_TYPE), instr(C.DATA_TYPE, '(') -1))),
            'VARCHAR2', C.DATA_LENGTH+1,
            'CHAR', C.DATA_LENGTH+1,
            'DATE', &DATLEN+1,
            'TIMESTAMP', 15 + B.DATA_SCALE+1,
            'FLOAT', 49,
            'INT', 48,
            'FIXP', C.DATA_PRECISION+2+sign(nvl(C.DATA_SCALE,0)),
            null), 1)) SUM2,
        E.MAXCOL MAXCOL
  from ALL_TAB_COLUMNS C,
       ALL_TAB_COLUMNS B,
       ALL_TAB_COLUMNS A,
       (select max(COLUMN_ID) MAXCOL
         from ALL_TAB_COLUMNS where TABLE_NAME = '&TABELLE' and OWNER = '&EIGENTUEMER') E
  where A.TABLE_NAME = '&TABELLE'
  and   B.TABLE_NAME(+) = '&TABELLE'
  and   C.TABLE_NAME = '&TABELLE'
  and   A.OWNER = '&EIGENTUEMER'
  and   B.OWNER(+) = '&EIGENTUEMER'
  and   C.OWNER = '&EIGENTUEMER'
  and   C.COLUMN_ID <= A.COLUMN_ID
  and   B.COLUMN_ID(+) = C.COLUMN_ID-1
  group by A.COLUMN_ID, A.COLUMN_NAME, A.DATA_TYPE, A.NULLABLE, E.MAXCOL) D
order by X1;

select 'EXTRAKT_DATTIM                 date "YYYYMMDD"' from dual;
select ')' from dual;

spool off

--
-- Generation of Teradata-Fastload-File
--

spool &1-&2..fld

select '.logon ${LOGON}' from dual;
select 'set record vartext "&DELIMI";' from dual;
prompt


select 'drop table &NEU_TABELLE;' from dual;
select 'drop table &NEU_TABELLE._ERR1;' from dual;
select 'drop table &NEU_TABELLE._ERR2;' from dual;

prompt

select 'create multiset table &NEU_TABELLE (' from dual;
select decode(COLUMN_ID, B.MINCOL, '   ', '  ,')||
  rpad(COLUMN_NAME, 33)||
  decode(substr(DATA_TYPE, 1, decode(instr(DATA_TYPE, '('), 0, length(DATA_TYPE), instr(DATA_TYPE, '(') -1)),
    'DATE', decode('&3', 'DT', 'timestamp(0)', 'D', 'date'),
    'TIMESTAMP', 'timestamp('||DATA_SCALE||')',
    'VARCHAR2', 'varchar('||DATA_LENGTH||') casespecific',
    'CHAR', 'char('||DATA_LENGTH||') casespecific',
    'FLOAT', 'float',
    'NUMBER', decode(DATA_SCALE, null, 'float',
      decode(DATA_PRECISION, null, 'integer',
      decode(sign(19-DATA_PRECISION), 1,
        decode(DATA_SCALE, 0, decode(sign(3-DATA_PRECISION), 1, 'byteint', decode(sign(5-DATA_PRECISION), 1, 'smallint', 'integer')),
          'dec('||DATA_PRECISION||','||DATA_SCALE||')'), 'float')))
  )||
  decode(NULLABLE, 'N', ' not null')
from  ALL_TAB_COLUMNS, (select max(COLUMN_ID) MAXCOL, min(COLUMN_ID) MINCOL
                        from ALL_TAB_COLUMNS where TABLE_NAME = '&TABELLE' and OWNER = '&EIGENTUEMER') B
where TABLE_NAME = '&TABELLE'
and   OWNER = '&EIGENTUEMER'
order by COLUMN_ID;

select '  ,EXTRAKT_DAT                      date not null' from dual;
select '  ,LOAD_DAT                         date not null' from dual;

select
  decode(C.POSITION, 1, ') primary index (', '  ,')||C.COLUMN_NAME
from
  ALL_TABLES A,
  ALL_CONSTRAINTS B,
  ALL_CONS_COLUMNS C
where
  A.OWNER = '&EIGENTUEMER'
and
  A.TABLE_NAME = '&TABELLE'
and
  A.OWNER = B.OWNER(+)
and
  A.TABLE_NAME = B.TABLE_NAME(+)
and
  B.OWNER = C.OWNER(+)
and
  B.CONSTRAINT_NAME = C.CONSTRAINT_NAME(+)
and
  B.CONSTRAINT_TYPE = 'P'
order by C.POSITION asc;

select ');' from dual;

prompt

select 'begin loading &NEU_TABELLE' from dual;
select 'errorfiles &NEU_TABELLE._ERR1, &NEU_TABELLE._ERR2;' from dual;
prompt
PROMPT  define
select D.COLUMN_ID X1, D.DATA_TYPE X2,
  '  '||rpad(D.COLUMN_NAME, 33)||' (varchar('||(D.SUM2-D.SUM1)||')'||
  decode(D.NULLABLE, 'Y', ', nullif '' ''', null)||'),'
from  (select A.COLUMN_ID, A.COLUMN_NAME, A.DATA_TYPE, A.NULLABLE,
        sum(nvl(decode(decode(B.DATA_TYPE,'NUMBER',
          decode(sign(nvl(B.DATA_PRECISION,0))+sign(B.DATA_SCALE),
            null,'FLOAT',0,'INT','FIXP'), substr(B.DATA_TYPE, 1, decode(instr(B.DATA_TYPE, '('), 0, length(B.DATA_TYPE), instr(B.DATA_TYPE, '(') -1))),
            'VARCHAR2', B.DATA_LENGTH,
            'CHAR', B.DATA_LENGTH,
            'DATE', &DATLEN,
            'TIMESTAMP', 15 + B.DATA_SCALE,
            'FLOAT', 49,
            'INT', 48,
            'FIXP', B.DATA_PRECISION+1+sign(B.DATA_SCALE),
            null), 0)) SUM1,
        sum(nvl(decode(decode(C.DATA_TYPE,'NUMBER',
          decode(sign(nvl(C.DATA_PRECISION,0))+sign(C.DATA_SCALE),
            null,'FLOAT',0,'INT','FIXP'), substr(C.DATA_TYPE, 1, decode(instr(C.DATA_TYPE, '('), 0, length(C.DATA_TYPE), instr(C.DATA_TYPE, '(') -1))),
            'VARCHAR2', C.DATA_LENGTH,
            'CHAR', C.DATA_LENGTH,
            'DATE', &DATLEN,
            'TIMESTAMP', 15 + C.DATA_SCALE,
            'FLOAT', 49,
            'INT', 48,
            'FIXP', C.DATA_PRECISION+1+sign(C.DATA_SCALE),
            null), 1)) SUM2,
        E.MAXCOL MAXCOL
  from ALL_TAB_COLUMNS C,
       ALL_TAB_COLUMNS B,
       ALL_TAB_COLUMNS A,
       (select max(COLUMN_ID) MAXCOL
        from ALL_TAB_COLUMNS where TABLE_NAME = '&TABELLE' and OWNER = '&EIGENTUEMER') E
  where A.TABLE_NAME = '&TABELLE'
  and   B.TABLE_NAME(+) = '&TABELLE'
  and   C.TABLE_NAME = '&TABELLE'
  and   A.OWNER = '&EIGENTUEMER'
  and   B.OWNER(+) = '&EIGENTUEMER'
  and   C.OWNER = '&EIGENTUEMER'
  and   C.COLUMN_ID <= A.COLUMN_ID
  and   B.COLUMN_ID(+) = C.COLUMN_ID-1
  group by A.COLUMN_ID, A.COLUMN_NAME, A.DATA_TYPE, A.NULLABLE, E.MAXCOL) D
order by X1;

select '  EXTRAKT_DAT                       (varchar(8))' from dual;
select 'file=${WORK}/&1-&2..lst;' from dual;
prompt

select 'insert into &NEU_TABELLE' from dual;
select 'values (' from dual;
select D.COLUMN_ID X1, D.DATA_TYPE X2,
  '  :'||D.COLUMN_NAME||
  decode(substr(D.DATA_TYPE, 1, decode(instr(D.DATA_TYPE, '('), 0, length(D.DATA_TYPE), instr(D.DATA_TYPE, '(') -1)),
    'DATE', rpad(' ', 32 - length(D.COLUMN_NAME))||decode('&3', 'D', ' (date, format ''', ' (format ''')||'&DATFORM2'')',
    'TIMESTAMP', rpad(' ', 32 - length(D.COLUMN_NAME))||' (format ''YYYYMMDDHHMISS.S('||D.DATA_SCALE||')'')',
    '')||','
from (select A.COLUMN_ID, A.COLUMN_NAME, A.DATA_TYPE, A.NULLABLE, A.DATA_SCALE,
        sum(nvl(decode(decode(B.DATA_TYPE,'NUMBER',
          decode(sign(nvl(B.DATA_PRECISION,0))+sign(B.DATA_SCALE),
            null,'FLOAT',0,'INT','FIXP'),substr(B.DATA_TYPE, 1, decode(instr(B.DATA_TYPE, '('), 0, length(B.DATA_TYPE), instr(B.DATA_TYPE, '(') -1))),
            'VARCHAR2', B.DATA_LENGTH+1,
            'CHAR', B.DATA_LENGTH+1,
            'DATE', &DATLEN+1,
            'TIMESTAMP', 15 + B.DATA_SCALE + 1,
            'FLOAT', 49,
            'INT', 48,
            'FIXP', B.DATA_PRECISION+2+sign(nvl(B.DATA_SCALE,0)),
            null), 0)) SUM1,
        sum(nvl(decode(decode(C.DATA_TYPE,'NUMBER',
          decode(sign(nvl(C.DATA_PRECISION,0))+sign(C.DATA_SCALE),
            null,'FLOAT',0,'INT','FIXP'),substr(C.DATA_TYPE, 1, decode(instr(C.DATA_TYPE, '('), 0, length(C.DATA_TYPE), instr(C.DATA_TYPE, '(') -1))),
            'VARCHAR2', C.DATA_LENGTH+1,
            'CHAR', C.DATA_LENGTH+1,
            'DATE', &DATLEN+1,
            'TIMESTAMP', 15 + B.DATA_SCALE + 1,
            'FLOAT', 49,
            'INT', 48,
            'FIXP', C.DATA_PRECISION+2+sign(nvl(C.DATA_SCALE,0)),
            null), 1)) SUM2,
        E.MAXCOL MAXCOL
  from  ALL_TAB_COLUMNS C,
        ALL_TAB_COLUMNS B,
        ALL_TAB_COLUMNS A,
        (select max(COLUMN_ID) MAXCOL
          from ALL_TAB_COLUMNS where TABLE_NAME = '&TABELLE' and OWNER = '&EIGENTUEMER') E
  where A.TABLE_NAME = '&TABELLE'
  and   B.TABLE_NAME(+) = '&TABELLE'
  and   C.TABLE_NAME = '&TABELLE'
  and   A.OWNER = '&EIGENTUEMER'
  and   B.OWNER(+) = '&EIGENTUEMER'
  and   C.OWNER = '&EIGENTUEMER'
  and   C.COLUMN_ID <= A.COLUMN_ID
  and   B.COLUMN_ID(+) = C.COLUMN_ID-1
  group by A.COLUMN_ID, A.COLUMN_NAME, A.DATA_TYPE, A.NULLABLE, E.MAXCOL, A.DATA_SCALE) D
order by X1;
select '  :EXTRAKT_DAT                      (format ''YYYYMMDD''),' from dual;
select '  current_date                      (format ''YYYYMMDD'')' from dual;
select ');' from dual;
prompt
select 'end loading;' from dual;
prompt
select 'logoff;' from dual;

spool off

--
-- Generation of SQL-File for the Unload
--

spool &1-&2..sql
PROMPT set pages 0 hea off term off echo off feed off verify off arraysize 1 pause off trimspool on trim on

prompt whenever sqlerror exit failure rollback
prompt whenever oserror exit failure rollback

select 'set lines '||
  sum(decode(decode(DATA_TYPE,'NUMBER',decode(sign(nvl(DATA_PRECISION,0))+sign(DATA_SCALE),
              null,'FLOAT',0,'INT','FIXP'), substr(DATA_TYPE, 1, decode(instr(DATA_TYPE, '('), 0, length(DATA_TYPE), instr(DATA_TYPE, '(') -1))),
      'VARCHAR2',DATA_LENGTH+1,
      'CHAR',DATA_LENGTH+1,
      'DATE',&DATLEN+1,
      'TIMESTAMP', 15 + DATA_SCALE + 1,
      'FLOAT',49,
      'INT',48,
      'FIXP',decode(DATA_SCALE,0,DATA_PRECISION+2,DATA_PRECISION+3),1) + 1 + 20)
from  ALL_TAB_COLUMNS
where TABLE_NAME = '&TABELLE'
and   OWNER = '&EIGENTUEMER';

prompt
prompt alter session set NLS_TERRITORY='AMERICA'
PROMPT /
prompt

select 'spool ${WORK}/&1-&2..lst' from dual;

select decode(COLUMN_ID, B.MINCOL, 'select ', '    ||''&DELIMI''||')||
  decode(substr(DATA_TYPE, 1, decode(instr(DATA_TYPE, '('), 0, length(DATA_TYPE), instr(DATA_TYPE, '(') -1)),
    'DATE','to_char('||COLUMN_NAME||','||'''&DATFORM'''||')',
    'TIMESTAMP', 'to_char('||COLUMN_NAME||','||'''YYYYMMDDHH24MISSxFF'')',
    'VARCHAR2', 'translate(ltrim(rtrim('||COLUMN_NAME||')), chr(10)||chr(13)||''&DELIMI'', ''&CRDELIMI.&CRDELIMI.&DELIMI2'')',
    'CHAR', 'translate(ltrim(rtrim('||COLUMN_NAME||')), chr(10)||chr(13)||''&DELIMI'', ''&CRDELIMI.&CRDELIMI.&DELIMI2'')',
    'NUMBER', 'to_char('||COLUMN_NAME||')',
  COLUMN_NAME)
from  ALL_TAB_COLUMNS, (select max(COLUMN_ID) MAXCOL, min(COLUMN_ID) MINCOL
                        from ALL_TAB_COLUMNS where TABLE_NAME = '&TABELLE' and OWNER = '&EIGENTUEMER') B
where TABLE_NAME = '&TABELLE'
and   OWNER = '&EIGENTUEMER'
order by COLUMN_ID;

select '    ||''&DELIMI''||to_char(sysdate, ''YYYYMMDD'')' from dual;

select 'from &EIGENTUEMER..&TABELLE' from dual;
-- PROMPT where ROWNUM <= 1000                          -- for evaluation purposes
PROMPT /
PROMPT spool off

spool off

