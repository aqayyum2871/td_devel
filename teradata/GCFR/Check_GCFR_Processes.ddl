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
        WHEN Column_Errors.Num_INP_Object_Columns = 0 THEN 'N'
        ELSE 'Y'
     END AS INP_Object_Found
    ,processes.Out_DB_Name
    ,processes.Out_Object_Name
    ,CASE
        WHEN Column_Errors.Num_OUT_Object_Columns = 0 THEN 'N'
        ELSE 'Y'
     END AS OUT_Object_Found
    ,processes.Target_TableDatabaseName
    ,processes.Target_TableName
    ,CASE
        WHEN Column_Errors.Num_Target_Table_Columns = 0 THEN 'N'
        ELSE 'Y'
     END AS Target_Table_Found
    ,COALESCE(Column_Errors.Num_INP_Object_Columns, 0) AS Num_INP_Object_Columns
    ,COALESCE(Column_Errors.Num_OUT_Object_Columns, 0) AS Num_OUT_Object_Columns
    ,COALESCE(Column_Errors.Num_Target_Table_Columns, 0) AS Num_Target_Table_Columns
    ,Column_Errors.TCE_OUT_Target_Diff
    ,Column_Errors.TCE_INP_OUT_Diff
    ,Column_Errors.TCE_in_Target
    ,CASE
        WHEN processes.process_type IN (23, 24, 25) AND Column_Errors.TCE_in_Tfm_KeyCol = 0 AND (Column_Errors.Num_Key_Columns = 0 OR Column_Errors.Num_Key_Columns IS NULL) THEN 1
        WHEN processes.process_type IN (23, 24, 25) THEN Column_Errors.TCE_in_Tfm_KeyCol
        ELSE 0
     END AS TCE_in_Transform_KeyCol
    ,CASE
        WHEN processes.process_type IN (24, 25) AND Column_Errors.Num_tech_col_type2 = 0 THEN 1
        WHEN processes.process_type IN (23)     AND Column_Errors.Num_tech_col_type2 > 0 THEN 1
        ELSE 0
     END AS TCE_in_Process_Type
    ,CASE
        WHEN Streams.Cycle_Freq_Code = 0 AND Column_Errors.Num_tech_col_type1 < 10 THEN 1
        WHEN Streams.Cycle_Freq_Code > 0 AND Column_Errors.Num_tech_col_type1 < 8 THEN 1
        ELSE 0
     END AS TCE_in_Tech_Columns
    ,Column_Errors.TCE_OUT_Target_Diff + Column_Errors.TCE_INP_OUT_Diff + Column_Errors.TCE_in_Target + TCE_in_Transform_KeyCol + TCE_in_Process_Type + TCE_in_Tech_Columns AS Sum_TCE

FROM <GCFR_V>.gcfr_process AS processes

LEFT JOIN <GCFR_V>.gcfr_system AS source_system
  ON source_system.ctl_id = processes.ctl_id

LEFT JOIN <GCFR_V>.gcfr_process_type AS process_type
  ON process_type.Process_Type = processes.Process_Type

LEFT JOIN <GCFR_V>.GCFR_Stream AS Streams
ON Streams.stream_key = processes.stream_key

LEFT JOIN
    (
        SELECT
            x01.process_name
            ,SUM(
                    CASE
                        WHEN XXY.GCFR_tech_column_type = 0 AND INP_Object_Columns.columnname IS NOT NULL THEN 1
                        ELSE 0
                    END
                ) AS Num_INP_Object_Columns
            ,SUM(
                    CASE
                        WHEN XXY.GCFR_tech_column_type = 0 AND OUT_Object_Columns.columnname IS NOT NULL THEN 1
                        ELSE 0
                    END
                ) AS Num_OUT_Object_Columns
            ,SUM(
                    CASE
                        WHEN XXY.GCFR_tech_column_type = 0 AND Target_Table_Columns.columnname IS NOT NULL THEN 1
                        ELSE 0
                    END
                ) AS Num_Target_Table_Columns
            ,SUM(
                    CASE
                        WHEN Transform_KeyCol.Key_column IS NOT NULL THEN 1
                        ELSE 0
                    END
                ) AS Num_Key_Columns
            ,SUM(
                    (CASE
                        WHEN x01.process_type IN (23)     AND XXY.GCFR_tech_column_type IN (1, 2) AND INP_Object_Columns.columnname IS NOT NULL THEN 1
                        WHEN x01.process_type IN (24, 25) AND XXY.GCFR_tech_column_type IN (1)    AND INP_Object_Columns.columnname IS NOT NULL THEN 1
                        ELSE 0
                     END)
                ) AS TCE_tech_column_in_INP_Object
            ,SUM(
                    (CASE
                        WHEN XXY.GCFR_tech_column_type = 1 AND OUT_Object_Columns.columnname IS NOT NULL THEN 1
                        ELSE 0
                     END)
                ) AS num_tech_column_in_OUT_Object
            ,SUM(
                    (CASE
                        WHEN x01.process_type IN (13,14,17,18,20,41,42,43,44) AND OUT_Object_Columns.columnname IS NOT NULL AND Target_Table_Columns.columnname IS NULL THEN 1
                        WHEN x01.process_type IN (13,14,17,18,20,41,42,43,44) AND OUT_Object_Columns.columnname IS NULL AND Target_Table_Columns.columnname IS NOT NULL THEN 1
                        ELSE 0
                     END)
                ) AS TCE_OUT_Target_Diff
            ,SUM(
                    (CASE
                        WHEN XXY.GCFR_tech_column_type > 0 THEN 0
                        WHEN x01.process_type IN (23,24,25) AND INP_Object_Columns.columnname IS NOT NULL AND OUT_Object_Columns.columnname IS NULL THEN 1
                        WHEN x01.process_type IN (23,24,25) AND INP_Object_Columns.columnname IS NULL AND OUT_Object_Columns.columnname IS NOT NULL THEN 1
                        ELSE 0
                     END)
                ) AS TCE_INP_OUT_Diff
            ,SUM(
                    (CASE
                        WHEN XXY.GCFR_tech_column_type > 0 THEN 0
                        WHEN x01.process_type IN (23,24,25) AND Target_Table_Columns.Nullable = 'N' AND Target_Table_Columns.DefaultValue IS NULL AND OUT_Object_Columns.columnname IS NULL THEN 1
                        WHEN x01.process_type IN (23,24,25) AND Target_Table_Columns.columnname IS NULL AND (INP_Object_Columns.columnname IS NOT NULL OR OUT_Object_Columns.columnname IS NOT NULL) THEN 1
                        ELSE 0
                     END)
                ) AS TCE_in_Target
            ,SUM(
                    (CASE
                        WHEN x01.process_type IN (23,24,25) AND Transform_KeyCol.Key_column IS NOT NULL AND Target_Table_Columns.columnname IS NOT NULL AND OUT_Object_Columns.columnname IS NOT NULL THEN 0 -- OK
                        WHEN x01.process_type IN (23,24,25) AND Transform_KeyCol.Key_column IS NULL THEN 0 -- OK
                        ELSE 1 -- Not OK
                     END)
                ) AS TCE_in_Tfm_KeyCol
            ,SUM(
                    (CASE
                        WHEN XXY.GCFR_tech_column_type = 1 THEN 1
                        ELSE 0
                     END)
                ) AS Num_tech_col_type1
            ,SUM(
                    (CASE
                        WHEN XXY.GCFR_tech_column_type = 2 THEN 1
                        ELSE 0
                     END)
                ) AS Num_tech_col_type2

        FROM <GCFR_V>.gcfr_process AS x01
        
        JOIN
            (
                -- generate list of all columns (INP, OUT, Target) related to that process
                SELECT y01.process_name, y02.columnname
                      ,CAST((CASE
                                WHEN y02.columnname IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id') THEN 1
                                WHEN y02.columnname IN ('GCFR_Delta_Action_Code') THEN 2
                                ELSE 0
                            END) AS BYTEINT) AS GCFR_tech_column_type
                  FROM <GCFR_V>.gcfr_process AS y01
                  JOIN dbc.columnsv AS y02
                    ON y02.databasename = y01.In_DB_Name
                   AND y02.tablename    = y01.In_Object_Name
                 UNION
                SELECT y03.process_name, y04.columnname
                      ,CAST((CASE
                                WHEN y04.columnname IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id') THEN 1
                                WHEN y04.columnname IN ('GCFR_Delta_Action_Code') THEN 2
                                ELSE 0
                            END) AS BYTEINT) AS GCFR_tech_column_type
                  FROM <GCFR_V>.gcfr_process AS y03
                  JOIN dbc.columnsv AS y04
                    ON y04.databasename = y03.Out_DB_Name
                   AND y04.tablename    = y03.Out_Object_Name
                 UNION
                SELECT y05.process_name, y06.columnname
                      ,CAST((CASE
                                WHEN y06.columnname IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id') THEN 1
                                WHEN y06.columnname IN ('GCFR_Delta_Action_Code') THEN 2
                                ELSE 0
                            END) AS BYTEINT) AS GCFR_tech_column_type
                  FROM <GCFR_V>.gcfr_process AS y05
                  JOIN dbc.columnsv AS y06
                    ON y06.databasename = y05.Target_TableDatabaseName
                   AND y06.tablename    = y05.Target_TableName
                 UNION
                SELECT y07.process_name, y08.key_column
                      ,CAST((CASE
                                WHEN y08.key_column IN ('start_date', 'end_date', 'start_ts', 'end_ts', 'record_deleted_flag', 'ctl_id', 'process_name', 'process_id', 'update_process_name', 'update_process_id') THEN 1
                                WHEN y08.key_column IN ('GCFR_Delta_Action_Code') THEN 2
                                ELSE 0
                            END) AS BYTEINT) AS GCFR_tech_column_type
                  FROM <GCFR_V>.gcfr_process AS y07
                  JOIN <GCFR_V>.gcfr_transform_keycol AS y08
                    ON y08.Out_DB_Name     = y07.Out_DB_Name
                   AND y08.Out_Object_Name = y07.Out_Object_Name
            ) AS XXY
        ON x01.process_name = XXY.process_name
        
        LEFT JOIN dbc.columnsv AS INP_Object_Columns
          ON INP_Object_Columns.databasename = x01.In_DB_Name
         AND INP_Object_Columns.tablename    = x01.In_Object_Name
         AND INP_Object_Columns.columnname   = XXY.columnname
        
        LEFT JOIN dbc.columnsv AS OUT_Object_Columns
          ON OUT_Object_Columns.databasename = x01.Out_DB_Name
         AND OUT_Object_Columns.tablename    = x01.Out_Object_Name
         AND OUT_Object_Columns.columnname   = XXY.columnname
        
        LEFT JOIN dbc.columnsv AS Target_Table_Columns
          ON Target_Table_Columns.databasename = x01.Target_TableDatabaseName
         AND Target_Table_Columns.tablename    = x01.Target_TableName
         AND Target_Table_Columns.columnname   = XXY.columnname

        LEFT JOIN <GCFR_V>.GCFR_Transform_KeyCol AS Transform_KeyCol
          ON Transform_KeyCol.out_db_name     = x01.Out_DB_Name
         AND Transform_KeyCol.out_object_name = x01.Out_Object_Name
         AND Transform_KeyCol.Key_column      = XXY.columnname

        GROUP BY 1
    ) AS Column_Errors
ON Column_Errors.process_name = processes.process_name

WHERE processes.process_type <> 11
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
comment on column <GCFR_V>.Check_GCFR_Processes.Num_INP_Object_Columns is 'Number of Data Columns in Input Object';
comment on column <GCFR_V>.Check_GCFR_Processes.Num_OUT_Object_Columns is 'Number of Data Columns in Output Object';
comment on column <GCFR_V>.Check_GCFR_Processes.Num_Target_Table_Columns is 'Number of Data Columns in Target Table';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_OUT_Target_Diff is 'Transform Column Error: the columnames between Output Object and Target Table do not match';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_INP_OUT_Diff is 'Transform Column Error: the columnames between Input and Output Objects do not match';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_in_Target is 'Transform Column Error: target column is defined as not null and has no default value and is missing in Output Object';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_in_Transform_KeyCol is 'Transform Column Error: no Columns defined as Key in GCFR_Transform_KeyCol or defined Key does not exist as column in Target Table';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_in_Process_Type is 'Transform Column Error: Process_Type is defined as delta, but missing column GCFR_Delta_Action_Code or vice versa';
comment on column <GCFR_V>.Check_GCFR_Processes.TCE_in_Tech_Columns is 'Transform Column Error: Too few GCFR technical columns depending on Stream-Cycle-Frequency-Code';
comment on column <GCFR_V>.Check_GCFR_Processes.Sum_TCE is 'Summarize all TCE* columns to show errors (easy to order in result set), a number greater then zero will very likely cause an abort in the GCFR process';
