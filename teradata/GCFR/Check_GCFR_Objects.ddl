REPLACE VIEW <GCFR_V>.Check_GCFR_Objects AS
SELECT
    TRIM(objts.databasename) AS DBName
    ,TRIM(objts.tablename) AS ObjName
    ,CAST((CASE
        WHEN objts.databasename = '<BASE_T>' THEN 'Core'
        WHEN objts.databasename = '<BASE_V>' THEN 'Core'
        WHEN objts.databasename = '<INP_V>' THEN 'Inp'
        WHEN objts.databasename = '<OUT_V>' THEN 'Out'
        WHEN objts.databasename = '<UTLFW_V>' THEN 'Utl'
     END) AS VARCHAR(5)) AS Layer_Name
    ,COALESCE(Processes_In_Obj.count_Process_In, 0) AS Used_as_Input_Count
    ,COALESCE(Processes_Out_Obj.count_Process_Out, 0) AS Used_as_Output_Count
    ,COALESCE(Processes_Target_Obj.count_Process_Target, 0) AS Used_as_Target_Count
    ,Used_as_Input_Count + Used_as_Output_Count + Used_as_Target_Count AS Used_at_all

FROM dbc.tablesv AS objts

LEFT JOIN
	(
        SELECT trim(In_DB_Name) as In_DB_Name, trim(In_Object_Name) as In_Object_Name, COUNT(*) AS count_Process_In
        FROM <GCFR_V>.gcfr_process
        GROUP BY 1,2
    ) AS Processes_In_Obj
ON Processes_In_Obj.In_DB_Name = DBName
AND Processes_In_Obj.In_Object_Name = ObjName

LEFT JOIN
	(
        SELECT trim(Out_DB_Name) as Out_DB_Name, trim(Out_Object_Name) as Out_Object_Name, COUNT(*) AS count_Process_Out
        FROM <GCFR_V>.gcfr_process
        GROUP BY 1,2
    ) AS Processes_Out_Obj
ON Processes_Out_Obj.Out_DB_Name = DBName
AND Processes_Out_Obj.Out_Object_Name = ObjName

LEFT JOIN
	(
        SELECT trim(Target_TableDatabaseName) as Target_TableDatabaseName, trim(Target_TableName) as Target_TableName, COUNT(*) AS count_Process_Target
        FROM <GCFR_V>.gcfr_process
        GROUP BY 1,2
    ) AS Processes_Target_Obj
ON Processes_Target_Obj.Target_TableDatabaseName = DBName
AND Processes_Target_Obj.Target_TableName = ObjName

WHERE objts.tablekind IN ('V', 'T', 'O')
AND objts.databasename IN ('<BASE_V>', '<BASE_T>', '<INP_V>', '<OUT_V>', '<UTLFW_V>')
AND TRIM(objts.tablename) NOT LIKE ALL ('%Next_Id', '%Next_Id_Log', '%Log')
;

comment on <GCFR_V>.Check_GCFR_Objects as 'Show objects in certain databases, if they are used in any GCFR_Process either as Input/Output or Target'
;
