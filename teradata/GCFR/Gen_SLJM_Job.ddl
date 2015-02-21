REPLACE VIEW <GCFR_V>.Gen_SLJM_Job AS
SELECT
     X01.stream_name
    ,X01.target_tabledatabasename
    ,X01.target_tablename
    ,X01.Type_Order
    ,X01.SLJM_Regular_Step
    ,X01.SLJM_Bteq_Step
    ,X01.Process_Type
    ,X01.Target_Order
    ,ROW_NUMBER() OVER (ORDER BY X01.stream_Name, X01.Type_Order, X01.Target_Tablename, X01.Target_Order) AS Absolute_Order
FROM
    (
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,TRIM((CASE
                WHEN t01.target_tablename IS NULL THEN CAST(((ROW_NUMBER() OVER (PARTITION BY t01.stream_key, t01.process_type ORDER BY t01.process_name)) (FORMAT '99999999')) AS VARCHAR(10))
                ELSE t01.target_tablename
             END)) AS target_tablename
            ,CASE
                WHEN TRIM(t01.target_tabledatabasename) LIKE '%STG' THEN 1
                WHEN TRIM(t01.target_tabledatabasename) LIKE '%UTLFW' THEN 2
                WHEN TRIM(t01.target_tabledatabasename) LIKE '%SRCI' THEN 3
                WHEN TRIM(t01.target_tabledatabasename) LIKE '%CORE' THEN 4
                ELSE 0
             END AS Type_Order
            ,'    GCFR '||(CASE
                           WHEN t01.process_type = 11 THEN 'Register_Data_Set_Availability '
                           WHEN t01.process_type = 13 THEN 'TPT_Load                       '
                           WHEN t01.process_type = 21 THEN 'Bkey_PP                             '
                           WHEN t01.process_type = 22 THEN 'Bmap_PP                             '
                           WHEN t01.process_type = 23 THEN 'Tfm_Full_Apply                      '
                           WHEN t01.process_type = 24 THEN 'Tfm_Delta_Apply                     '
                           WHEN t01.process_type = 25 THEN 'GCFR_Tfm_Insert_Append              '
                       END)||TRIM(t01.stream_key)||' '||t01.process_name AS SLJM_Regular_Step
            ,CASE
                WHEN t01.process_type IN (21, 22, 23, 24, 25) THEN '    ExecGCFR GCFR_'||t01.process_name
                ELSE SLJM_Regular_Step
             END AS SLJM_Bteq_Step
            ,CASE
                 WHEN t01.process_type = 11 THEN 'Data available'
                 WHEN t01.process_type = 13 THEN 'Load'
                 WHEN t01.process_type = 21 THEN 'BKEY'
                 WHEN t01.process_type = 22 THEN 'BMAP'
                 WHEN t01.process_type IN (23,24,25) THEN 'Transform'
             END AS Process_Type
            ,ROW_NUMBER() OVER (PARTITION BY t02.stream_name, t01.target_tablename
                ORDER BY
                     CASE
                        WHEN TRIM(t01.target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(t01.target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(t01.target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(t01.target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END
                    ,t01.process_type
                    ,t01.process_name
             ) AS Target_Order
        FROM <GCFR_V>.gcfr_process AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
        WHERE t01.process_type IN (11, 13, 21, 22, 23, 24, 25)
        UNION ALL
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,t01.target_tablename
            ,t01.Type_Order
            ,'sub' AS SLJM_Regular_Step
            ,'sub' AS SLJM_Bteq_Step
            ,CAST(NULL AS VARCHAR(20)) AS Process_Type
            ,CAST(0 AS INTEGER) AS Target_Order
        FROM
            (
                SELECT
                    stream_key
                    ,CASE
                        WHEN TRIM(target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END AS Type_Order
                    ,target_tabledatabasename
                    ,target_tablename
                FROM
                    (
                        SELECT
                             stream_key
                            ,target_tabledatabasename
                            ,TRIM((CASE
                                WHEN target_tablename IS NULL THEN CAST(((ROW_NUMBER() OVER (PARTITION BY stream_key, process_type ORDER BY process_name)) (FORMAT '99999999')) AS VARCHAR(10))
                                ELSE target_tablename
                             END)) AS target_tablename
                        FROM
                            <GCFR_V>.gcfr_process
                        WHERE
                            process_type IN (11, 13, 21, 22, 23, 24, 25)
                    ) AS X01
                GROUP BY 1,2,3,4
             ) AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
        UNION ALL
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,t01.target_tablename
            ,t01.Type_Order
            ,'end' AS SLJM_Regular_Step
            ,'end' AS SLJM_Bteq_Step
            ,CAST(NULL AS VARCHAR(20)) AS Process_Type
            ,CAST(999999999 AS INTEGER) AS Target_Order
        FROM
            (
                SELECT
                    stream_key
                    ,CASE
                        WHEN TRIM(target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END AS Type_Order
                    ,target_tabledatabasename
                    ,target_tablename
                FROM
                    (
                        SELECT
                             stream_key
                            ,target_tabledatabasename
                            ,TRIM((CASE
                                WHEN target_tablename IS NULL THEN CAST(((ROW_NUMBER() OVER (PARTITION BY stream_key, process_type ORDER BY process_name)) (FORMAT '99999999')) AS VARCHAR(10))
                                ELSE target_tablename
                             END)) AS target_tablename
                        FROM
                            <GCFR_V>.gcfr_process
                        WHERE
                            process_type IN (11, 13, 21, 22, 23, 24, 25)
                    ) AS X01
                GROUP BY 1,2,3,4
             ) AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
        UNION ALL
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,t01.target_tablename
            ,t01.Type_Order
            ,'# Target Table: ' || TRIM(t01.target_tabledatabasename)||'.'||TRIM(t01.target_tablename) AS SLJM_Regular_Step
            ,'# Target Table: ' || TRIM(t01.target_tabledatabasename)||'.'||TRIM(t01.target_tablename) AS SLJM_Bteq_Step
            ,CAST(NULL AS VARCHAR(20)) AS Process_Type
            ,CAST(-1 AS INTEGER) AS Target_Order
        FROM
            (
                SELECT
                    stream_key
                    ,CASE
                        WHEN TRIM(target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END AS Type_Order
                    ,target_tabledatabasename
                    ,Target_TableName
                FROM
                    <GCFR_V>.gcfr_process
                WHERE
                    process_type IN (11, 13, 21, 22, 23, 24, 25)
                GROUP BY stream_key, target_tabledatabasename, Type_Order, Target_TableName
             ) AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
        WHERE t01.target_tablename IS NOT NULL
        UNION ALL
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,t01.target_tablename
            ,t01.Type_Order
            ,'' AS SLJM_Regular_Step
            ,'' AS SLJM_Bteq_Step
            ,CAST(NULL AS VARCHAR(20)) AS Process_Type
            ,CAST(-2 AS INTEGER) AS Target_Order
        FROM
            (
                SELECT
                    stream_key
                    ,CASE
                        WHEN TRIM(target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END AS Type_Order
                    ,Target_TableDatabaseName
                    ,target_tablename
                FROM
                    (
                        SELECT
                             stream_key
                            ,target_tabledatabasename
                            ,TRIM((CASE
                                WHEN target_tablename IS NULL THEN CAST(((ROW_NUMBER() OVER (PARTITION BY stream_key, process_type ORDER BY process_name)) (FORMAT '99999999')) AS VARCHAR(10))
                                ELSE target_tablename
                             END)) AS target_tablename
                        FROM
                            <GCFR_V>.gcfr_process
                        WHERE
                            process_type IN (11, 13, 21, 22, 23, 24, 25)
                    ) AS X01
                GROUP BY 1,2,3,4
             ) AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
        UNION ALL
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,t01.target_tablename
            ,t01.Type_Order
            ,'' AS SLJM_Regular_Step
            ,'' AS SLJM_Bteq_Step
            ,CAST(NULL AS VARCHAR(20)) AS Process_Type
            ,CAST(1 AS INTEGER) AS Target_Order
        FROM
            (
                SELECT
                    stream_key
                    ,CASE
                        WHEN TRIM(target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END AS Type_Order
                    ,target_tabledatabasename
                    ,CAST('ZZZZZZZZZ' AS VARCHAR(150)) AS Target_TableName
                FROM
                    <GCFR_V>.gcfr_process
                WHERE
                    process_type IN (11, 13, 21, 22, 23, 24, 25)
                GROUP BY 1, 3, 2, 4
             ) AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
        UNION ALL
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,t01.target_tablename
            ,t01.Type_Order
            ,'# synchronization point' AS SLJM_Regular_Step
            ,'# synchronization point' AS SLJM_Bteq_Step
            ,CAST(NULL AS VARCHAR(20)) AS Process_Type
            ,CAST(2 AS INTEGER) AS Target_Order
        FROM
            (
                SELECT
                    stream_key
                    ,CASE
                        WHEN TRIM(target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END AS Type_Order
                    ,target_tabledatabasename
                    ,CAST('ZZZZZZZZZ' AS VARCHAR(150)) AS Target_TableName
                FROM
                    <GCFR_V>.gcfr_process
                WHERE
                    process_type IN (11, 13, 21, 22, 23, 24, 25)
                GROUP BY 1, 3, 2, 4
             ) AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
        UNION ALL
        SELECT
             t02.stream_name
            ,t01.target_tabledatabasename
            ,t01.target_tablename
            ,t01.Type_Order
            ,'true' AS SLJM_Regular_Step
            ,'true' AS SLJM_Bteq_Step
            ,CAST(NULL AS VARCHAR(20)) AS Process_Type
            ,CAST(3 AS INTEGER) AS Target_Order
        FROM
            (
                SELECT
                    stream_key
                    ,CASE
                        WHEN TRIM(target_tabledatabasename) LIKE '%STG' THEN 1
                        WHEN TRIM(target_tabledatabasename) LIKE '%UTLFW' THEN 2
                        WHEN TRIM(target_tabledatabasename) LIKE '%SRCI' THEN 3
                        WHEN TRIM(target_tabledatabasename) LIKE '%CORE' THEN 4
                        ELSE 0
                     END AS Type_Order
                    ,target_tabledatabasename
                    ,CAST('ZZZZZZZZZ' AS VARCHAR(150)) AS Target_TableName
                FROM
                    <GCFR_V>.gcfr_process
                WHERE
                    process_type IN (11, 13, 21, 22, 23, 24, 25)
                GROUP BY 1, 3, 2, 4
             ) AS t01
        JOIN <GCFR_V>.gcfr_stream AS t02
        ON t01.stream_key = t02.stream_key
    ) AS X01
--ORDER BY Absolute_Order
;

comment on view <GCFR_V>.Gen_SLJM_Job is 'Generated SLJM steps for all Streams based on GCFR_Process. Order by column Absolute_Order to have execution sequence (but be aware if any complex dependencies exist, which cannot be seen in GCFR_Process table)!'
;
