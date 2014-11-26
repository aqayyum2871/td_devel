REPLACE PROCEDURE <Enter Database here>.SP_GEN_121_VIEWS
    (
        IN sourcedb VARCHAR(500),
        IN viewdb   VARCHAR(500)
    )

BEGIN

    -- This view is for generating 1:1 views in one database based on tables in another database
    -- The views get "V_" as prefix (if the table has "T_" as prefix, it will be removed)

    -- The owner of this procedure requires to have those additional priviliges
    -- select on base table database (source)
    -- create/drop view on view database (target)

    -- If the view already exists, it will be replaced
    -- Comments on tables/views/columns are migrated as well

    DECLARE dname VARCHAR(500);
    DECLARE tname VARCHAR(500);
    DECLARE tlist varCHAR(10000);
    DECLARE commentlast integer;
    DECLARE commentpos integer;
    DECLARE CommentStringNew varchar(1000);

    --L1:
    FOR atable AS gettable
    CURSOR FOR
        SELECT  TRIM(BOTH FROM t01.DatabaseName) TAB_DB
               ,TRIM(BOTH FROM t01.TableName) TAB_NAME
               ,t01.DatabaseName
               ,t01.TableName
               ,'V_' || (CASE WHEN SUBSTRING(t01.TableName FROM 1 FOR 2) = 'T_' THEN SUBSTRING(TRIM(t01.TableName) FROM 3) ELSE TRIM(t01.TableName) END) VIEW_NAME
               ,CASE WHEN t02.TableName IS NULL THEN 'CREATE' ELSE 'REPLACE' END MyCommand
               ,t01.CommentString
          FROM DBC.TABLES t01
          LEFT OUTER JOIN DBC.TABLES t02
            ON t02.DATABASENAME = :viewdb
           AND 'V_' || (CASE WHEN SUBSTRING(t01.TableName FROM 1 FOR 2) = 'T_' THEN SUBSTRING(t01.TableName FROM 3) ELSE t01.TableName END) = t02.TableName
           AND t02.TABLEKIND = 'V'
         WHERE t01.DATABASENAME = :sourcedb
           AND t01.TABLEKIND IN ('T', 'O')    -- T = regular table, O = NoPI table
         ORDER BY TAB_DB, TAB_NAME
    DO

        SET tname = atable.TableName;
        SET dname = atable.DatabaseName;
        SET tlist = null;

        --L2:
        FOR alist AS getlist
        CURSOR FOR
            SELECT TRIM(BOTH FROM ColumnName) AS COLUMN_NAME
              FROM DBC.Columns
             WHERE DatabaseName = dname
               AND TableName = tname
        DO

            IF tlist IS NULL THEN
                SET tlist = alist.COLUMN_NAME;
            ELSE
                SET tlist = (tlist || ', ' || alist.COLUMN_NAME);
            END IF;

        END FOR;

        CALL DBC.SYSEXECSQL(atable.MyCommand || ' VIEW ' || :viewdb || '.' || atable.VIEW_NAME ||
                            ' AS LOCKING ROW FOR ACCESS SELECT ' || tlist || ' FROM ' || atable.TAB_DB || '.' || atable.TAB_NAME || ';');

        IF atable.CommentString IS NOT NULL THEN
            SET CommentStringNew = atable.CommentString;
            SET commentpos = INDEX(CommentStringNew, '''');
            SET commentlast = commentpos;

            IF commentlast > 0 THEN
                WHILE (commentlast > 0)
                DO
                    SET CommentStringNew = SUBSTR(CommentStringNew, 1, commentpos) || SUBSTR(CommentStringNew, commentpos);
                    SET commentlast = INDEX(SUBSTR(CommentStringNew, commentpos + 2), '''');
                    SET commentpos = commentpos + commentlast + 1;
                END WHILE;
            END IF;
            CALL DBC.SYSEXECSQL('COMMENT ON VIEW ' || :viewdb || '.' || atable.VIEW_NAME || ' IS ''' || CommentStringNew || ''';');
        END IF;

        --L3:
        FOR alist AS getlist
        CURSOR FOR
            SELECT TRIM(BOTH FROM t01.ColumnName) AS COLUMN_NAME, t01.CommentString
              FROM DBC.Columns as t01
             WHERE t01.DatabaseName = dname
               AND t01.TableName = tname
        DO

            IF alist.CommentString IS NOT NULL THEN
                SET CommentStringNew = alist.CommentString;
                SET commentpos = INDEX(CommentStringNew, '''');
                SET commentlast = commentpos;

                IF commentlast > 0 THEN
                    WHILE (commentlast > 0)
                    DO
                        SET CommentStringNew = SUBSTR(CommentStringNew, 1, commentpos) || SUBSTR(CommentStringNew, commentpos);
                        SET commentlast = INDEX(SUBSTR(CommentStringNew, commentpos + 2), '''');
                        SET commentpos = commentpos + commentlast + 1;
                    END WHILE;
                END IF;
                CALL DBC.SYSEXECSQL('COMMENT ON COLUMN ' || :viewdb || '.' || atable.VIEW_NAME || '.' || alist.COLUMN_NAME || ' IS ''' || CommentStringNew || ''';');
            END IF;

        END FOR;

    END FOR;

END;
