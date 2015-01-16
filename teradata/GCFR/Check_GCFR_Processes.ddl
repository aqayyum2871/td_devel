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
     END AS INP_View_Found
    ,processes.Out_DB_Name
    ,processes.Out_Object_Name
    ,CASE
        WHEN OUT_Views.DBName IS NULL AND processes.Out_DB_Name IS NOT NULL THEN 'N'
        WHEN OUT_Views.DBName IS NOT NULL THEN 'Y'
     END AS OUT_View_Found
    ,processes.Target_TableDatabaseName
    ,processes.Target_TableName
    ,CASE
        WHEN Target_Tables.DBName IS NULL AND processes.Out_DB_Name IS NOT NULL THEN 'N'
        WHEN Target_Tables.DBName IS NOT NULL THEN 'Y'
    END AS Target_Table_Found

FROM <GCFR_V>.gcfr_process AS processes

LEFT JOIN <GCFR_V>.gcfr_system AS source_system
ON source_system.ctl_id = processes.ctl_id

LEFT JOIN <GCFR_V>.gcfr_process_type AS process_type
ON process_type.Process_Type = processes.Process_Type

LEFT JOIN (
        SELECT TRIM(databasename) AS DBName, TRIM(tablename) AS TabName
        FROM dbc.tablesv
        WHERE tablekind = 'V'
        AND databasename IN ('<INP_V>', '<UTLFW_V>', '<STG_V>', '<OI_V>')
        AND tablename NOT LIKE ALL ('BKP%')
    ) AS INP_Views

ON INP_Views.DBName = processes.In_DB_Name
AND INP_Views.TabName = processes.In_Object_Name

LEFT JOIN (
        SELECT TRIM(databasename) AS DBName, TRIM(tablename) AS TabName
        FROM dbc.tablesv
        WHERE tablekind = 'V'
        AND databasename IN ('<OUT_V>', '<UTLFW_V>', '<STG_V>', '<OI_V>')
        AND tablename NOT LIKE ALL ('BKP%')
    ) AS OUT_Views

ON OUT_Views.DBName = processes.Out_DB_Name
AND OUT_Views.TabName = processes.Out_Object_Name

LEFT JOIN (
        SELECT TRIM(databasename) AS DBName, TRIM(tablename) AS TabName
        FROM dbc.tablesv
        WHERE tablekind IN ('T', 'O')
        AND databasename IN ('<UTLFW_T>', '<UTLFW_V>', '<STG_V>', '<OI_V>')
        AND tablename NOT LIKE ALL ('BKP%')
    ) AS Target_Tables

ON Target_Tables.DBName = processes.Target_TableDatabaseName
AND Target_Tables.TabName = processes.Target_TableName
;

comment on <GCFR_V>.Check_GCFR_Processes as 'Show GCFR processes an look if Input/Output or target object exists or not'
;
