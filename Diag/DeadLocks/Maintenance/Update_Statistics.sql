DECLARE @SQL NVARCHAR(MAX);
DECLARE @TableName NVARCHAR(128);

DECLARE table_cursor CURSOR FOR
SELECT TABLE_SCHEMA + '.' + TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE' 
ORDER BY TABLE_NAME;

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Command
    SET @SQL = 'UPDATE STATISTICS ' + @TableName + ' WITH FULLSCAN; PRINT ''Updated statistics for: ' + @TableName + '''';


    EXEC sp_executesql @SQL;

    FETCH NEXT FROM table_cursor INTO @TableName;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;
