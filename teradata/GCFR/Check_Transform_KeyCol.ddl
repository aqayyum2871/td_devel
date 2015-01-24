REPLACE VIEW <GCFR_V>.Check_Transform_KeyCol AS
SELECT
    t01.process_name
    ,t01.process_type
    ,t02.description AS Process_Description
    ,t01.out_Db_name
    ,t01.out_object_name
    ,t01.target_tabledatabasename
    ,t01.target_tablename
    ,COALESCE(t03.Count_Key_Columns, 0) AS Count_Key_Columns

FROM <GCFR_V>.GCFR_Process AS t01

LEFT JOIN <GCFR_V>.GCFR_Process_Type AS t02
ON t02.process_type = t01.process_type

LEFT JOIN
    (
        SELECT out_db_name, out_object_name, COUNT(*) AS Count_Key_Columns
        FROM <GCFR_V>.GCFR_Transform_KeyCol
        GROUP BY 1,2
    ) AS t03
ON t03.out_db_name = t01.out_db_name
AND t03.out_object_name = t01.out_object_name

WHERE t01.process_type IN (23,24)
;

comment on view <GCFR_V>.Check_Transform_KeyCol is 'Check if all Transform processes have Key-Columns defined'
;
