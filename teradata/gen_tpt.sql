insert into TPT_Loader_Scripts (Table_Owner, Table_Name, POS1, POS2, TPT_Text)
SELECT trim(databasename), trim(tablename), 0 (SMALLINT), 1 (SMALLINT), 'USING CHARACTER SET '||Character_Set (VARCHAR(300))  FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 10, 1, 'DEFINE JOB load_' || TRIM(tablename) || '(  ' (VARCHAR(300))  FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 20, 1, ' DEFINE OPERATOR W_1_op_load' || TRIM(tablename) (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 30, 1 ,' TYPE ' || Loader_Type (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 40, 1 ,' SCHEMA *' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 50, 1 ,' ATTRIBUTES' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 60, 1 ,' (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 70, 1 ,'  VARCHAR UserName, VARCHAR UserPassword, VARCHAR LogTable, VARCHAR TargetTable,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 80, 1 ,'  INTEGER BufferSize, INTEGER ErrorLimit, INTEGER MaxSessions, INTEGER MinSessions,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 90, 1 ,'  INTEGER TenacityHours, INTEGER TenacitySleep, VARCHAR AccountID, VARCHAR DateForm,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 100, 1 ,'  VARCHAR ErrorTable1, VARCHAR ErrorTable2, VARCHAR NotifyExit, VARCHAR NotifyExitIsDLL,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 110, 1 ,'  VARCHAR NotifyLevel, VARCHAR NotifyMethod, VARCHAR NotifyString, VARCHAR PauseAcq,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 120, 1 ,'  VARCHAR PrivateLogName, VARCHAR TdpId, VARCHAR TraceLevel, VARCHAR WorkingDatabase' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 130, 1 ,' );' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 140, 1 ,' DEFINE SCHEMA W_0_sc_load' || TRIM(tablename) (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 150, 1 ,' (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(t01.databasename), trim(t01.tablename), 160, ColumnId,'    '||(case when length(TRIM(ColumnName)) < 28 then 'X_'||cast(TRIM(otranslate(translate(ColumnName using LATIN_TO_UNICODE), '#$', '__')) as varchar(255)) else cast(TRIM(otranslate(translate(ColumnName using LATIN_TO_UNICODE), '#$', '__')) as varchar(255)) end)||' VARCHAR('|| TRIM( (CASE
                                                              WHEN Columntype = 'DA' THEN 20
                                                              WHEN ColumnType = 'D' THEN (decimaltotaldigits + 5)
                                                              WHEN ColumnType = 'I ' THEN 12
                                                              WHEN ColumnType = 'I1' THEN 5
                                                              WHEN ColumnType = 'I2' THEN 7
                                                              WHEN ColumnType = 'I4' THEN 12
                                                              WHEN ColumnType = 'I8' THEN 40
                                                              WHEN ColumnType IN ('CV','CF') and CharType = 1 THEN ColumnLength
                                                              WHEN ColumnType IN ('CV','CF') and CharType = 2 THEN (ColumnLength*3)
                                                              WHEN ColumnType = 'A1' then 1000
                                                              ELSE (ColumnLength*2) END ) )||')'||(CASE WHEN columnid LT lastcol THEN ',' ELSE ' ' END)
FROM dbc.Columns t01
JOIN (
		SELECT trim(databasename) AS databasename, trim(tablename) AS tablename, MAX(columnid) AS lastcol
		FROM dbc.Columns
		JOIN TPT_Loader_Script_Owner
		on databasename=Table_Owner
		GROUP BY trim(databasename), trim(tablename)
	) t02
on t01.databasename = t02.databasename
and t01.tablename = t02.tablename
join dbc.tables t03
on t01.databasename = t03.databasename
and t01.tablename = t03.tablename
where t03.TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 170, 1,' );' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 180, 1,' DEFINE OPERATOR W_0_op_load' || TRIM(tablename) (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 190, 1,' TYPE DATACONNECTOR PRODUCER' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 200, 1,' SCHEMA W_0_sc_load' || TRIM(tablename) (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 210, 1,' ATTRIBUTES' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 220, 1,' (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 230, 1,'  VARCHAR FileName, VARCHAR Format, VARCHAR OpenMode, INTEGER BlockSize,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 240, 1,'  INTEGER BufferSize, INTEGER RetentionPeriod, INTEGER RowsPerInstance, INTEGER SecondarySpace,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 250, 1,'  INTEGER UnitCount, INTEGER VigilElapsedTime, INTEGER VigilWaitTime, INTEGER VolumeCount,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 260, 1,'  VARCHAR AccessModuleName, VARCHAR AccessModuleInitStr,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 270, 1,'  VARCHAR DirectoryPath, VARCHAR ExpirationDate,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 280, 1,'  VARCHAR IndicatorMode, VARCHAR PrimarySpace, VARCHAR PrivateLogName, VARCHAR RecordFormat,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 290, 1,'  VARCHAR RecordLength, VARCHAR SpaceUnit, VARCHAR TextDelimiter, VARCHAR VigilNoticeFileName,' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 300, 1,'  VARCHAR VigilStartTime, VARCHAR VigilStopTime, VARCHAR VolSerNumber, VARCHAR UnitType' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 310, 1,' );' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 320, 1,' APPLY' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 330, 1,'  (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 340, 1,'   ''INSERT INTO ' || TRIM(databasename) || '.' || TRIM(tablename) ||'(' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(t01.databasename), trim(t01.tablename), 350, ColumnId,'    '||TRIM(ColumnName)||(CASE WHEN columnid LT lastcol THEN ',' ELSE ' ' END)
FROM dbc.Columns t01
JOIN (
		SELECT trim(databasename) AS databasename, trim(tablename) AS tablename, MAX(columnid) AS lastcol
		FROM dbc.Columns
		JOIN TPT_Loader_Script_Owner
		on databasename=Table_Owner
		GROUP BY trim(databasename), trim(tablename)
	) t02
on t01.databasename = t02.databasename
and t01.tablename = t02.tablename
join dbc.tables t03
on t01.databasename = t03.databasename
and t01.tablename = t03.tablename
where t03.TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 360, 1,'    )' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 370, 1,'    VALUES' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 380, 1,'    (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(t01.databasename), trim(t01.tablename), 390, ColumnId,'    :'||(case when length(TRIM(ColumnName)) < 28 then 'X_'||cast(TRIM(otranslate(translate(ColumnName using LATIN_TO_UNICODE), '#$', '__')) as varchar(255)) else cast(TRIM(otranslate(translate(ColumnName using LATIN_TO_UNICODE), '#$', '__')) as varchar(255)) end)||(CASE WHEN columnid LT lastcol THEN ',' ELSE ' ' END)
FROM dbc.Columns t01
JOIN (
		SELECT trim(databasename) AS databasename, trim(tablename) AS tablename, MAX(columnid) AS lastcol
		FROM dbc.Columns
		JOIN TPT_Loader_Script_Owner
		on databasename=Table_Owner
		GROUP BY trim(databasename), trim(tablename)
	) t02
on t01.databasename = t02.databasename
and t01.tablename = t02.tablename
join dbc.tables t03
on t01.databasename = t03.databasename
and t01.tablename = t03.tablename
where t03.TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 400, 1,'   );'''(VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 410, 1,'  )'(VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 420, 1,' TO OPERATOR' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 430, 1,' (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 440, 1,'  W_1_op_load' || TRIM(tablename) || '[1]' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 450, 1,'  ATTRIBUTES' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 460, 1,'  (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 470, 1,'   UserName = ' || TRIM(Logon_User) || ',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 480, 1,'   UserPassword = ' || TRIM(Logon_PWD) || ',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 485, 1,'   WorkingDatabase = ''' || TRIM(DB_Log_Table) || ''',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 490, 1,'   LogTable = ''' || TRIM(DB_Log_Table) || '.T' || cast((current_timestamp(0) (format 'YYYYMMDDHHMISS')) as varchar(30)) || cast((row_number() over (order by databasename, tablename)) as varchar(10)) || '_log'',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 491, 1,'   ErrorTable1 = ''' || TRIM(DB_Log_Table) || '.T' || cast((current_timestamp(0) (format 'YYYYMMDDHHMISS')) as varchar(30)) || cast((row_number() over (order by databasename, tablename)) as varchar(10)) || '_ET1'',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 492, 1,'   ErrorTable2 = ''' || TRIM(DB_Log_Table) || '.T' || cast((current_timestamp(0) (format 'YYYYMMDDHHMISS')) as varchar(30)) || cast((row_number() over (order by databasename, tablename)) as varchar(10)) || '_ET2'',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 500, 1,'   TargetTable = ''' || TRIM(Table_Owner) || '.' || TRIM(tablename) || ''',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 510, 1,'   MaxSessions = ' || TRIM(Max_Sessions) || ',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 520, 1,'   TdpId = ' || TRIM(TDPID) (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 530, 1,'  )'(VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 540, 1,' )'(VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 550, 1,' SELECT '(VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(t01.databasename), trim(t01.tablename), 560, ColumnId,'    '||(case when length(TRIM(ColumnName)) < 28 then 'X_'||cast(TRIM(otranslate(translate(ColumnName using LATIN_TO_UNICODE), '#$', '__')) as varchar(255)) else cast(TRIM(otranslate(translate(ColumnName using LATIN_TO_UNICODE), '#$', '__')) as varchar(255)) end)||(CASE WHEN columnid LT lastcol THEN ',' ELSE ' ' END)
FROM dbc.Columns t01
JOIN (
		SELECT trim(databasename) AS databasename, trim(tablename) AS tablename, MAX(columnid) AS lastcol
		FROM dbc.Columns
		JOIN TPT_Loader_Script_Owner
		on databasename=Table_Owner
		GROUP BY trim(databasename), trim(tablename)
	) t02
on t01.databasename = t02.databasename
and t01.tablename = t02.tablename
join dbc.tables t03
on t01.databasename = t03.databasename
and t01.tablename = t03.tablename
where t03.TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 570, 1,' FROM OPERATOR' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 580, 1,' (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 590, 1,'  W_0_op_load' || TRIM(tablename) || '[1]' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 600, 1,'  ATTRIBUTES' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 610, 1,'  (' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 620, 1,'   DirectoryPath = ''' || TRIM(Directory_Path) || ''',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 630, 1,'   FileName = ''' || TRIM(Table_Owner) || '.' || TRIM(tablename) || '.dat'',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 640, 1,'   Format = ''BINARY'',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 650, 1,'   OpenMode = ''Read'',' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 660, 1,'   IndicatorMode = ''Y''' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 680, 1,'  )' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 690, 1,' );' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
UNION ALL
SELECT trim(databasename), trim(tablename), 700, 1,');' (VARCHAR(100)) FROM dbc.tables JOIN TPT_Loader_Script_Owner on databasename=Table_Owner where TableKind = 'T'
;
