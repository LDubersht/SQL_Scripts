CREATE TABLE #Result (
    TableName NVARCHAR(255),
    ColumnName NVARCHAR(255),
    DataType NVARCHAR(50),
    Value NVARCHAR(MAX)
);

DECLARE @TableName NVARCHAR(255);
DECLARE @ColumnName NVARCHAR(255);
DECLARE @DataType NVARCHAR(50);
DECLARE @SQL NVARCHAR(MAX);

DECLARE @Tables TABLE (TableName NVARCHAR(255));
INSERT INTO @Tables (TableName)
VALUES 
    ('Table1'),
    ('Table2'),
    ('Table3'); 


DECLARE TableCursor CURSOR FOR 
SELECT TableName 
FROM @Tables;

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE ColumnCursor CURSOR FOR 
    SELECT COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @TableName
          AND DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar', 'text', 'int', 'bigint', 'smallint', 'tinyint');

    OPEN ColumnCursor;
    FETCH NEXT FROM ColumnCursor INTO @ColumnName, @DataType;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- create query
        SET @SQL = N'
            INSERT INTO #Result (TableName, ColumnName, DataType, Value)
            SELECT TOP 10 
                ''' + @TableName + ''',
                ''' + @ColumnName + ''',
                ''' + @DataType + ''',
                CAST(' + QUOTENAME(@ColumnName) + ' AS NVARCHAR(MAX))
            FROM ' + QUOTENAME(@TableName) + '
            WHERE ' + QUOTENAME(@ColumnName) + ' IS NOT NULL;
        ';

        -- exec
        EXEC sp_executesql @SQL;

        FETCH NEXT FROM ColumnCursor INTO @ColumnName, @DataType;
    END;

    CLOSE ColumnCursor;
    DEALLOCATE ColumnCursor;

    FETCH NEXT FROM TableCursor INTO @TableName;
END;

CLOSE TableCursor;
DEALLOCATE TableCursor;


SELECT * FROM #Result;


DROP TABLE #Result;
