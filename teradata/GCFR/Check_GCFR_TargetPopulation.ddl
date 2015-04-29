REPLACE VIEW <GCFR_V>.Check_GCFR_TargetPopulation AS
SELECT
    targets.DBName AS Target_Table_DB
    ,targets.TabName AS Target_Table_Name
    ,COALESCE(processes.count_population, 0) AS Number_GCFR_Processes

FROM
    (
        SELECT TRIM(databasename) AS DBName, TRIM(tablename) AS TabName
        FROM dbc.tablesv
        WHERE tablekind IN ('T', 'O')
        AND databasename IN ('<STG_T>', '<OI_T>', '<BASE_T>')
        AND tablename NOT LIKE ALL ('BKP%') -- exclude any known temporary objects
    ) AS targets

LEFT JOIN
    (
        SELECT
            Target_TableDatabaseName, Target_TableName, COUNT(*) AS count_population
        FROM <GCFR_V>.gcfr_process
        GROUP BY 1, 2
    ) AS processes
ON processes.Target_TableDatabaseName = targets.DBName
AND processes.Target_TableName = targets.TabName
;

comment on <GCFR_V>.Check_GCFR_TargetPopulation as 'Show target tables and show number of processes populating it'
;
