SELECT
    TRIM(tablename) AS "DATA_STRUCTURE_NAME_DE5.0"
    ,TRIM(columnname) AS "DATA_ELEMENT_NAME"
    ,COALESCE(CommentString,'') AS "DATA_ELEMENT_DESC"
    ,'' AS "CUSTOM_PROPERTY1_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY2_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY3_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY4_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY5_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY6_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY7_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY8_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY9_NAME_HERE"
    ,'' AS "CUSTOM_PROPERTY10_NAME_HERE"
    ,TRIM((CASE
        WHEN columntype = 'CV' THEN 6
        WHEN columntype = 'CF' THEN 4
        WHEN columntype = 'DA' THEN 2
        WHEN columntype IN ('I', 'I1', 'I2', 'I4', 'I8') THEN 8
        WHEN columntype = 'TS' THEN 3
        WHEN columntype IN ('N', 'D') THEN 5
        WHEN columntype = 'T' THEN 7
        ELSE ''
     END)) AS "DATA_TYPE_CD"
    ,TRIM((CASE
        WHEN columntype IN ('CF', 'CV') THEN ColumnLength / CharType
        WHEN columntype IN ('D', 'N') THEN DecimalTotalDigits
        ELSE ''
     END)) AS "DATA_ELEMENT_LENGTH_INT"
    ,TRIM((CASE
        WHEN columntype IN ('D', 'N') THEN decimalFractionalDigits
        ELSE ''
     END)) AS "DATA_ELEMENT_PRECISION_INT"
    ,CAST(2 AS BYTEINT) AS "DATA_ELEMENT_TYPE_CD"
    ,Nullable
    ,ROW_NUMBER() OVER (PARTITION BY databasename, tablename ORDER BY columnid) AS "LOGICAL_SEQUENCE_NUMBER"
    ,ROW_NUMBER() OVER (PARTITION BY databasename, tablename ORDER BY columnid) AS "PHYSICAL_SEQUENCE_NUMBER"
    ,'' AS "PLACEHOLDER_TYPE_CD"
FROM dbc.columnsv
WHERE databasename = 'DEV1_T_STG'
ORDER BY databasename, TableName, ColumnName
;
