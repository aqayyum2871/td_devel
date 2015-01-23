REPLACE VIEW <GCFR_V>.Check_Transform_Process_Type AS
SELECT
    proc.Process_Name AS Process_Name
    ,proc.Target_TableDatabaseName AS Target_DB
    ,proc.Target_TableName
    ,proc.Process_Type AS Process_Type_from_Processes
    ,proc_types.description AS Process_Type_Description
    ,proc.in_db_name AS TX_View_DB
    ,proc.in_object_name AS TX_ViewName
    ,CASE
        WHEN View_Exists.tablename IS NULL THEN 'input TX view does not even exist'
        WHEN Check_View.col_name IS NULL AND proc.process_type = 23 THEN 'OK'
        WHEN Check_View.col_name IS NULL AND proc.process_type = 24 THEN 'Process defined as "Delta", but input TX view defined as "Full"'
        WHEN Check_View.col_name IS NOT NULL AND proc.process_type = 23 THEN 'Process defined as "Full", but input TX view defined as "Delta"'
        WHEN Check_View.col_name IS NOT NULL AND proc.process_type = 24 THEN 'OK'
    END AS compare_result

FROM <GCFR_V>.gcfr_process AS proc

LEFT JOIN dbc.tablesv AS View_Exists
ON TRIM(proc.in_db_name) = TRIM(View_Exists.databasename)
AND TRIM(proc.in_object_name) = TRIM(View_Exists.tablename)
AND View_Exists.tablekind = 'V'

LEFT JOIN (
        SELECT TRIM(t01.databasename) AS db_name, TRIM(t01.tablename) AS tab_name, TRIM(t01.columnname) AS col_name
        FROM dbc.columnsv AS t01
        JOIN dbc.tablesv AS t02
        ON t01.databasename = t02.databasename
        AND t01.tablename = t02.tablename
        WHERE t01.databasename = '<TXFM_INP_V>'
        AND t01.columnname = 'GCFR_Delta_Action_Code'
    ) AS Check_View
ON proc.in_db_name = Check_View.db_name
AND proc.in_object_name = Check_View.tab_name

LEFT JOIN <GCFR_V>.gcfr_process_type AS proc_types
ON proc_types.process_type = proc.process_type

WHERE proc.process_type IN (23,24)
;

comment on view <GCFR_V>.Check_Transform_Process_Type is 'Compares process_type definition in <GCFR_V>.GCFR_Process with input TX view definition in <TXFM_INP_V> if process_types match';
