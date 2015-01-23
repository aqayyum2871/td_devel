REPLACE VIEW <GCFR_V>.Gen_GCFR_Comments AS
SELECT CAST('comment on '||TRIM(t01.in_DB_Name)||'.'||TRIM(t01.in_Object_Name)||' as '''||
    (CASE
        WHEN t01.process_type = 21 THEN 'BKEY transformation view into '
        WHEN t01.process_type = 22 THEN 'BMAP transformation view into '
        WHEN t01.process_type = 23 THEN 'Full transformation view into '
        WHEN t01.process_type = 24 THEN 'Delta transformation view into '
        WHEN t01.process_type = 25 THEN 'Transaction transformation view into '
     END
    )||
    (CASE
        WHEN t01.Target_TableDatabaseName LIKE '%T_CORE' THEN 'Core'
        WHEN t01.Target_TableDatabaseName LIKE '%T_UTLFW' THEN 'GCFR'
        WHEN t01.Target_TableDatabaseName LIKE '%T_SRCI' THEN 'SRCI'
     END
    )
    ||' table '||TRIM(t01.Target_TableName)||
    (CASE
        WHEN t01.process_type = 21 THEN ', Key_Set_Id = '||TRIM(t01.key_set_id)||', Domain_ID = '||TRIM(t01.domain_Id)||' ('||COALESCE(TRIM(Domain_BKEY.description), 'not found in <UTL_V>.BKEY_Domain')||')'
        WHEN t01.process_type = 22 THEN ', Code_Set_Id = '||TRIM(t01.Code_set_id)||', Domain_ID = '||TRIM(t01.domain_Id)||' ('||COALESCE(TRIM(Domain_BMAP.description), 'not found in <UTL_V>.BMAP_Domain')||')'
        ELSE ''
     END
    )
    ||''';' AS VARCHAR(500)) AS SQL_Text
FROM <GCFR_V>.gcfr_process AS t01
LEFT JOIN <UTL_V>.BKEY_Domain AS Domain_BKEY
ON t01.key_set_id = Domain_BKEY.key_set_id
AND t01.domain_id = Domain_BKEY.domain_id
LEFT JOIN <UTL_V>.BMAP_Domain AS Domain_BMAP
ON t01.code_set_id = Domain_BMAP.code_set_id
AND t01.domain_id = Domain_BMAP.domain_id
WHERE t01.process_type IN (21,22,23,24,25)
UNION ALL
SELECT DISTINCT 'comment on '||TRIM(Out_DB_Name)||'.'||TRIM(Out_Object_Name)||' as '''||
    (CASE
        WHEN process_type = 21 THEN 'BKEY output view into '
        WHEN process_type = 22 THEN 'BMAP output view into '
        WHEN process_type IN (23,24,25) THEN 'Transformation output view into '
     END
    )||
    (CASE
        WHEN Target_TableDatabaseName LIKE '%T_CORE' THEN 'Core'
        WHEN Target_TableDatabaseName LIKE '%T_UTLFW' THEN 'GCFR'
        WHEN Target_TableDatabaseName LIKE '%T_SRCI' THEN 'SRCI'
     END
    )
    ||' table '||TRIM(Target_TableName)||''';'
FROM <GCFR_V>.gcfr_process
WHERE process_type IN (21,22,23,24,25)
;
