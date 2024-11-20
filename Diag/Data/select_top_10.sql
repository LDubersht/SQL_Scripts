CREATE TABLE #Result (
	SchemaName NVARCHAR(255),
    TableName NVARCHAR(255),
    ColumnName NVARCHAR(255),
    DataType NVARCHAR(50),
    Value NVARCHAR(MAX)
);

DECLARE @SchemaName NVARCHAR(255);
DECLARE @TableName NVARCHAR(255);
DECLARE @ColumnName NVARCHAR(255);
DECLARE @DataType NVARCHAR(50);
DECLARE @SQL NVARCHAR(MAX);

DECLARE @Tables TABLE (SchemaName NVARCHAR(255),TableName NVARCHAR(255));
INSERT INTO @Tables (SchemaName,TableName)
VALUES 
    ('dbo','T1'),
    ('dbo','T2');


DECLARE TableCursor CURSOR FOR 
SELECT SchemaName,TableName 
FROM @Tables;

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @SchemaName,@TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE ColumnCursor CURSOR FOR 
    SELECT COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = @TableName AND TABLE_SCHEMA = @SchemaName
          AND DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar', 'text', 'int', 'bigint', 'smallint', 'tinyint');

    OPEN ColumnCursor;
    FETCH NEXT FROM ColumnCursor INTO @ColumnName, @DataType;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- create query
        SET @SQL = N'
            INSERT INTO #Result (TableName, ColumnName, DataType, Value)
            SELECT TOP 2 
                ''' + @TableName + ''',
                ''' + @ColumnName + ''',
                ''' + @DataType + ''',
                CAST(' + QUOTENAME(@ColumnName) + ' AS NVARCHAR(MAX))
            FROM ' + QUOTENAME(@TableName) + '
            WHERE ' + QUOTENAME(@ColumnName) + ' IS NOT NULL;
        ';

		-- print

        -- exec
        EXEC sp_executesql @SQL;

        FETCH NEXT FROM ColumnCursor INTO @ColumnName, @DataType;
    END;

    CLOSE ColumnCursor;
    DEALLOCATE ColumnCursor;

    FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;
END;

CLOSE TableCursor;
DEALLOCATE TableCursor;


SELECT * FROM #Result;


DROP TABLE #Result;
