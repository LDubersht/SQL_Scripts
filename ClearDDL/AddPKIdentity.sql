DECLARE @TableName NVARCHAR(255);
DECLARE @SchemaName NVARCHAR(255);
DECLARE @SQL NVARCHAR(MAX);

DECLARE TableCursor CURSOR FOR
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND OBJECTPROPERTY(OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)), 'IsMsShipped') = 0;

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Проверяем наличие колонки с IDENTITY
    IF EXISTS (
        SELECT 1
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        WHERE t.name = @TableName
          AND t.schema_id = SCHEMA_ID(@SchemaName)
          AND c.is_identity = 1
    )
    BEGIN
        -- Получаем имя колонки с IDENTITY
        DECLARE @IdentityColumn NVARCHAR(255);
        SELECT TOP 1 @IdentityColumn = c.name
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        WHERE t.name = @TableName
          AND t.schema_id = SCHEMA_ID(@SchemaName)
          AND c.is_identity = 1;

        -- Проверяем, есть ли первичный ключ на колонке с IDENTITY
        IF NOT EXISTS (
            SELECT 1
            FROM sys.indexes i
            JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
            WHERE i.object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName))
              AND i.is_primary_key = 1
              AND ic.column_id = COLUMNPROPERTY(OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)), @IdentityColumn, 'ColumnID')
        )
        BEGIN
            -- Создаем первичный ключ на колонке с IDENTITY
            SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) +
                       ' ADD CONSTRAINT PK_' + @TableName + '_' + @IdentityColumn + 
                       ' PRIMARY KEY CLUSTERED (' + QUOTENAME(@IdentityColumn) + ');';
            PRINT @SQL;
            EXEC sp_executesql @SQL;
        END
    END
    ELSE
    BEGIN
        -- Добавляем колонку S_ID с IDENTITY
        SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) +
                   ' ADD S_ID INT IDENTITY(1,1);';
        PRINT @SQL;
        EXEC sp_executesql @SQL;

        -- Создаем первичный ключ на колонке S_ID
        SET @SQL = 'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) +
                   ' ADD CONSTRAINT PK_' + @TableName + '_S_ID PRIMARY KEY CLUSTERED (S_ID);';
        PRINT @SQL;
        EXEC sp_executesql @SQL;
    END

    FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;
END;

CLOSE TableCursor;
DEALLOCATE TableCursor;
