REPLACE VIEW <GCFR_V>.Check_GCFR_Processes AS
SELECT
    processes.Process_Name
    ,processes.Description AS Process_Description
    ,processes.Process_Type
    ,process_type.Process_Type_Name
    ,process_type.Description AS Process_Type_Description
    ,processes.ctl_id
    ,source_system.system_name
    ,source_system.description AS Source_System_Description
    ,processes.In_DB_Name
    ,processes.In_Object_Name
    ,CASE
        WHEN INP_Views.DBName IS NULL AND processes.In_DB_Name IS NOT NULL THEN 'N'
        WHEN INP_Views.DBName IS NOT NULL THEN 'Y'
     END AS INP_Object_Found
    ,processes.Out_DB_Name
    ,processes.Out_Object_Name
    ,CASE
        WHEN OUT_Views.DBName IS NULL AND processes.Out_DB_Name IS NOT NULL THEN 'N'
        WHEN OUT_Views.DBName IS NOT NULL THEN 'Y'
     END AS OUT_Object_Found
    ,processes.Target_TableDatabaseName
    ,processes.Target_TableName
    ,CASE
        WHEN Target_Tables.DBName IS NULL AND processes.Out_DB_Name IS NOT NULL THEN 'N' 
        WHEN Target_Tables.DBName IS NOT NULL THEN 'Y'
     END AS Target_Table_Found
    ,INP_Views.Num_Of_Columns AS Num_INP_Object_Columns
    ,OUT_Views.Num_Of_Columns AS Num_OUT_Object_Columns
    ,Target_Tables.Num_Of_Columns AS Num_Target_Table_Columns
    ,Column_Errors.TCE_OUT_Target_Diff
    ,Column_Errors.TCE_INP_OUT_Diff
    ,COALESCE(Column_Errors.TCE_in_Target, 1) AS TCE_in_Target
    ,CASE
        WHEN processes.process_type IN (23,24,25) AND Column_Errors.TCE_in_Tfm_KeyCol = 0 AND (Num_Tfm_KeyCol.Count_Key_Columns = 0 OR Num_Tfm_KeyCol.Count_Key_Columns IS NULL) THEN 1
        WHEN processes.process_type IN (23,24,25) THEN Column_Errors.TCE_in_Tfm_KeyCol
        ELSE 0
     END AS TCE_in_Transform_KeyCol
    ,Column_Errors.TCE_OUT_Target_Diff + Column_Errors.TCE_INP_OUT_Diff + Column_Errors.TCE_in_Target + TCE_in_Transform_KeyCol AS Sum_TCE

FROM <GCFR_V>.gcfr_process AS processes

LEFT JOIN <GCFR_V>.gcfr_system AS source_system
ON source_system.ctl_id = processes.ctl_id

LEFT JOIN <GCFR_V>.gcfr_process_type AS process_type
ON process_type.Process_Type = processes.Process_Type

LEFT JOIN
    (
        SELECT TRIM(t05.databasename) AS DBName, TRIM(t05.tablename) AS TabName, COUNT(*) Num_of_columns
        FROM dbc.tablesv AS t05
        JOIN dbc.columnsv AS t06
        ON t05.databasename = t06.databasename
        AND t05.tablename = t06.tablename
        WHERE t05.tablekind = 'V'
        AND t06.columnname NOT IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id', 'GCFR_Delta_Action_Code')
        GROUP BY 1,2
    ) AS INP_Views
ON INP_Views.DBName = processes.In_DB_Name
AND INP_Views.TabName = processes.In_Object_Name

LEFT JOIN (
        SELECT TRIM(t03.databasename) AS DBName, TRIM(t03.tablename) AS TabName, COUNT(*) Num_of_columns
        FROM dbc.tablesv AS t03
        JOIN dbc.columnsv AS t04
        ON t03.databasename = t04.databasename
        AND t03.tablename = t04.tablename
        WHERE t03.tablekind = 'V'
        AND t04.columnname NOT IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id', 'GCFR_Delta_Action_Code')
        GROUP BY 1,2
    ) AS OUT_Views
ON OUT_Views.DBName = processes.Out_DB_Name
AND OUT_Views.TabName = processes.Out_Object_Name

LEFT JOIN (
        SELECT TRIM(t01.databasename) AS DBName, TRIM(t01.tablename) AS TabName, COUNT(*) Num_of_columns
        FROM dbc.tablesv AS t01
        JOIN dbc.columnsv AS t02
        ON t01.databasename = t02.databasename
        AND t01.tablename = t02.tablename
        WHERE t01.tablekind IN ('T', 'O')
        AND t02.columnname NOT IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id', 'GCFR_Delta_Action_Code')
        GROUP BY 1,2
    ) AS Target_Tables
ON Target_Tables.DBName = processes.Target_TableDatabaseName
AND Target_Tables.TabName = processes.Target_TableName

LEFT JOIN
    (
        SELECT
            x01.process_name
            ,SUM((CASE
                WHEN x01.process_type IN (13,14,17,18,20,41,42,43,44) AND OUT_View_Columns.columnname IS NOT NULL AND Target_Table_Columns.columnname IS NULL THEN 1
                WHEN x01.process_type IN (13,14,17,18,20,41,42,43,44) AND OUT_View_Columns.columnname IS NULL AND Target_Table_Columns.columnname IS NOT NULL THEN 1
                ELSE 0
             END)) AS TCE_OUT_Target_Diff
            ,SUM((CASE
                WHEN x01.process_type IN (23,24,25) AND INP_View_Columns.columnname IS NOT NULL AND OUT_View_Columns.columnname IS NULL THEN 1
                WHEN x01.process_type IN (23,24,25) AND INP_View_Columns.columnname IS NULL AND OUT_View_Columns.columnname IS NOT NULL THEN 1
                ELSE 0
             END)) AS TCE_INP_OUT_Diff
            ,SUM((CASE
                WHEN x01.process_type IN (23,24,25) AND Target_Table_Columns.Nullable = 'N' AND Target_Table_Columns.DefaultValue IS NULL AND OUT_View_Columns.columnname IS NULL THEN 1
                WHEN x01.process_type IN (23,24,25) AND Target_Table_Columns.columnname IS NULL AND (INP_View_Columns.columnname IS NOT NULL OR OUT_View_Columns.columnname IS NOT NULL) THEN 1
                ELSE 0
             END)) AS TCE_in_Target
            ,SUM((CASE
                WHEN x01.process_type IN (23,24,25) AND Target_Table_Columns.columnname IS NULL AND Tranform_KeyCol.Key_column IS NOT NULL THEN 1
                ELSE 0
             END)) AS TCE_in_Tfm_KeyCol
        
        FROM <GCFR_V>.gcfr_process AS x01
        
        JOIN
            (
                SELECT y01.process_name, y02.columnname
                FROM <GCFR_V>.gcfr_process AS y01
                JOIN dbc.columnsv AS y02
                ON TRIM(y01.In_DB_Name) = TRIM(y02.databasename)
                AND TRIM(y01.In_Object_Name) = TRIM(y02.tablename)
                WHERE y02.columnname NOT IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id', 'GCFR_Delta_Action_Code')
                UNION
                SELECT y03.process_name, y04.columnname
                FROM <GCFR_V>.gcfr_process AS y03
                JOIN dbc.columnsv AS y04
                ON TRIM(y03.Out_DB_Name) = TRIM(y04.databasename)
                AND TRIM(y03.Out_Object_Name) = TRIM(y04.tablename)
                WHERE y04.columnname NOT IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id', 'GCFR_Delta_Action_Code')
                UNION
                SELECT y05.process_name, y06.columnname
                FROM <GCFR_V>.gcfr_process AS y05
                JOIN dbc.columnsv AS y06
                ON TRIM(y05.Target_TableDatabaseName) = TRIM(y06.databasename)
                AND TRIM(y05.Target_TableName) = TRIM(y06.tablename)
                WHERE y06.columnname NOT IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id', 'GCFR_Delta_Action_Code')
                UNION
                SELECT y07.process_name, y08.key_column
                FROM <GCFR_V>.gcfr_process AS y07
                JOIN <GCFR_V>.gcfr_transform_keycol AS y08
                ON TRIM(y07.Out_DB_Name) = TRIM(y08.Out_DB_Name)
                AND TRIM(y07.Out_Object_Name) = TRIM(y08.Out_Object_Name)
            ) AS XXY
        ON x01.process_name = XXY.process_name
        
        LEFT JOIN dbc.columnsv AS INP_View_Columns
        ON TRIM(x01.In_DB_Name) = TRIM(INP_View_Columns.databasename)
        AND TRIM(x01.In_Object_Name) = TRIM(INP_View_Columns.tablename)
        AND XXY.columnname = INP_View_Columns.columnname
        
        LEFT JOIN dbc.columnsv AS OUT_View_Columns
        ON TRIM(x01.Out_DB_Name) = TRIM(OUT_View_Columns.databasename)
        AND TRIM(x01.Out_Object_Name) = TRIM(OUT_View_Columns.tablename)
        AND XXY.columnname = OUT_View_Columns.columnname
        
        LEFT JOIN dbc.columnsv AS Target_Table_Columns
        ON TRIM(x01.Target_TableDatabaseName) = TRIM(Target_Table_Columns.databasename)
        AND TRIM(x01.Target_TableName) = TRIM(Target_Table_Columns.tablename)
        AND XXY.columnname = Target_Table_Columns.columnname

        LEFT JOIN <GCFR_V>.GCFR_Transform_KeyCol AS Tranform_KeyCol
        ON TRIM(x01.Out_DB_Name) = TRIM(Tranform_KeyCol.out_db_name)
        AND TRIM(x01.Out_Object_Name) = TRIM(Tranform_KeyCol.out_object_name)
        AND XXY.columnname = Tranform_KeyCol.Key_column

        GROUP BY 1
    ) AS Column_Errors
ON processes.process_name = Column_Errors.process_name

LEFT JOIN
    (
        SELECT out_db_name, out_object_name, COUNT(*) AS Count_Key_Columns
        FROM <GCFR_V>.GCFR_Transform_KeyCol
        GROUP BY 1,2
    ) AS Num_Tfm_KeyCol
ON processes.out_db_name = Num_Tfm_KeyCol.out_db_name
AND processes.out_object_name = Num_Tfm_KeyCol.out_object_name
;

comment on view <GCFR_V>.Check_GCFR_Processes is 'Show GCFR processes and extensively check and show inconsistencies';
comment on column <GCFR_V>.Check_GCFR_Processes.Process_Name is 'Process Name from GCFR_Process View';
comment on column <GCFR_V>.Check_GCFR_Processes.Process_Description is 'Process Description from GCFR_Process View';
comment on column <GCFR_V>.Check_GCFR_Processes.Process_Type is 'Process Type from GCFR_Process View';
comment on column <GCFR_V>.Check_GCFR_Processes.Process_Type_Name is 'Process Type Name from GCFR_Process_Type View';
comment on column <GCFR_V>.Check_GCFR_Processes.Process_Type_Description is 'Process Type Description from GCFR_Process_Type View';
comment on column <GCFR_V>.Check_GCFR_Processes.Ctl_Id is 'Source System ID from GCFR_Process View';
comment on column <GCFR_V>.Check_GCFR_Processes.System_Name is 'Source System Name from GCFR_System View';
comment on column <GCFR_V>.Check_GCFR_Processes.Source_System_Description is 'Source System Description from GCFR_System View';
comment on column <GCFR_V>.Check_GCFR_Processes.In_DB_Name is 'In which Database is the Input Object';
comment on column <GCFR_V>.Check_GCFR_Processes.In_Object_Name is 'The name of the Input Object';
comment on column <GCFR_V>.Check_GCFR_Processes.INP_Object_Found is 'Y=The Input Object has been found, N=The Input Object has not been found, N leads to an error in GCFR';
comment on column <GCFR_V>.Check_GCFR_Processes.Out_DB_Name is 'In which Database is the Output Object';
comment on column <GCFR_V>.Check_GCFR_Processes.Out_Object_Name is 'The name of the Output Object';
comment on column <GCFR_V>.Check_GCFR_Processes.OUT_Object_Found is 'Y=The Output Object has been found, N=The Output Object has not been found, N leads to an error in GCFR';
comment on column <GCFR_V>.Check_GCFR_Processes.Target_TableDatabaseName is 'In which Database is the Target Table';
comment on column <GCFR_V>.Check_GCFR_Processes.Target_TableName is 'The name of the Target Table';
comment on column <GCFR_V>.Check_GCFR_Processes.Target_Table_Found is 'Y=The Target Table has been found, N=The Target Table has not been found, N leads to an error in GCFR';
comment on column <GCFR_V>.Check_GCFR_Processes.Num_INP_Object_Columns is 'Number of Columns in Input Object';
comment on column <GCFR_V>.Check_GCFR_Processes.Num_OUT_Object_Columns is 'Number of Columns in Output Object';
comment on column <GCFR_V>.Check_GCFR_Processes.Num_Target_Table_Columns is 'Number of Columns in Target Table';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_OUT_Target_Diff is 'Transform Column Error: the columnames between Output Object and Target Table do not match';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_INP_OUT_Diff is 'Transform Column Error: the columnames between Input and Output Objects do not match';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_in_Target is 'Transform Column Error: target column is defined as not null and has no default value and is missing in Output Object';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_in_Transform_KeyCol is 'Transform Column Error: no Columns defined as Key in GCFR_Transform_KeyCol or defined Key does not exist as column in Target Table';
comment on column <GCFR_V>.Check_GCFR_Processes.Sum_TCE is 'Summarize all TCE* columns to show errors (easy to order in result set), a number greater then zero will very likely cause an abort in the GCFR process';
