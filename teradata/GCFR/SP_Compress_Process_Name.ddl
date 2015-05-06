REPLACE PROCEDURE <desired_database>.SP_Compress_Process_Name
    (
        IN inDB VARCHAR(500)
    )
BEGIN
    DECLARE dname VARCHAR(500);
    DECLARE tname VARCHAR(500);
    DECLARE tlist VARCHAR(10000);
    DECLARE iCols INTEGER;
    --L1:
    FOR atable AS gettable
    CURSOR FOR
        SELECT  TRIM(t01.Target_TableDatabaseName) AS TAB_DB
               ,TRIM(t01.Target_TableName) AS TAB_NAME
               ,TRIM(t01.Process_Name) AS Process_Name
               ,COUNT(*) AS Cols
          FROM <GCFR_V>.GCFR_Process AS t01
          JOIN DBC.COLUMNSV AS t02
            ON t02.DATABASENAME = t01.Target_TableDatabaseName
           AND t02.TableName = t01.Target_Tablename
         WHERE t01.Target_TableDatabaseName = :inDB
           AND t02.columnname IN ('Process_Name', 'Update_Process_Name')
         GROUP BY 1,2,3
         UNION ALL
        SELECT  TRIM(t01.Temp_DatabaseName) AS TAB_DB
               ,TRIM(t01.Process_Name) || '_IMG' AS TAB_NAME
               ,TRIM(t01.Process_Name) AS Process_Name
               ,COUNT(*) AS Cols
          FROM <GCFR_V>.GCFR_Process AS t01
          JOIN DBC.COLUMNSV AS t02
            ON t02.DATABASENAME = t01.Target_TableDatabaseName
           AND t02.TableName = t01.Target_Tablename
          JOIN dbc.tablesv AS t03
            ON t03.databasename = t01.temp_databasename
           AND t03.tablename = t01.Process_Name || '_IMG'
         WHERE t01.Temp_DatabaseName = :inDB
           AND t02.columnname IN ('Process_Name', 'Update_Process_Name')
         GROUP BY 1,2,3
         UNION ALL
        SELECT  TRIM(t01.Temp_DatabaseName) AS TAB_DB
               ,TRIM(t01.Process_Name) || '_INS' AS TAB_NAME
               ,TRIM(t01.Process_Name) AS Process_Name
               ,COUNT(*) AS Cols
          FROM <GCFR_V>.GCFR_Process AS t01
          JOIN DBC.COLUMNSV AS t02
            ON t02.DATABASENAME = t01.Target_TableDatabaseName
           AND t02.TableName = t01.Target_Tablename
          JOIN dbc.tablesv AS t03
            ON t03.databasename = t01.temp_databaseName
           AND t03.tablename = t01.Process_Name || '_INS'
         WHERE t01.Temp_DatabaseName = :inDB
           AND t02.columnname IN ('Process_Name', 'Update_Process_Name')
         GROUP BY 1,2,3
         ORDER BY 1,2,3
    DO

        IF tname IS NULL THEN
            -- first record of cursor
            SET tname = atable.TAB_NAME;
            SET dname = atable.TAB_DB;
            SET iCols = atable.Cols;
            SET tlist = '''' || atable.Process_Name || '''';
        ELSE
            IF dname = atable.TAB_DB AND tname = atable.TAB_NAME THEN
                -- table/database has not changed add new Process_Name to string
                SET tlist = tlist || ', ''' || atable.Process_Name || '''';
            ELSE
                -- table/database has changed execute previous table
                IF iCols = 2 THEN
                    -- only execute, if both columns are found in target table
                    CALL DBC.SYSEXECSQL('ALTER TABLE ' || dname || '.' || tname || ' add Process_Name compress (' || tlist || '), add Update_Process_Name compress (' || tlist || ');');
                END IF;

                -- set new values here
                SET tname = atable.TAB_NAME;
                SET dname = atable.TAB_DB;
                SET iCols = atable.Cols;
                SET tlist = '''' || atable.Process_Name || '''';
            END IF;
        END IF;

    END FOR;

    -- execute last table with last process name
    IF iCols = 2 THEN
        -- only execute, if both columns are found in target table
        CALL DBC.SYSEXECSQL('ALTER TABLE ' || dname || '.' || tname || ' add Process_Name compress (' || tlist || '), add Update_Process_Name compress (' || tlist || ');');
    END IF;

END;

-- the database holding that procedure requires create and drop table privileges on the targeted databases
