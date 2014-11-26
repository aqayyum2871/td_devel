-- Show Skew factor of tables in database
-- Change databasename

SELECT DatabaseName, TableName,SUM(CurrentPerm) AS CurrentPerm,SUM(PeakPerm) AS PeakPerm,
    (100 - (AVG(CurrentPerm)/MAX(CurrentPerm)*100)) AS SkewFactor
FROM Dbc.TableSize
WHERE DataBaseName = <DATABASE_NAME>
GROUP BY 1
ORDER BY 2
;
