USE DBA
DROP TABLE IF EXISTS QueuePK
CREATE TABLE QueuePK (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName NVARCHAR(255) NOT NULL,
    TableName NVARCHAR(255) NOT NULL,
    TaskStatus NVARCHAR(50) DEFAULT 'Pending', -- Возможные статусы: Pending, Processing, Completed
    LastUpdateTime DATETIME DEFAULT GETDATE()
);

INSERT INTO QueuePK (SchemaName, TableName)
SELECT TABLE_SCHEMA, TABLE_NAME
FROM Analytics.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND OBJECTPROPERTY(OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)), 'IsMsShipped') = 0;

USE Analytics
DECLARE @TaskId INT;
DECLARE @SchemaName NVARCHAR(255);
DECLARE @TableName NVARCHAR(255);
DECLARE @SQL NVARCHAR(MAX);
DECLARE @IdentityColumn NVARCHAR(255);

WHILE EXISTS (SELECT 1 FROM DBA..QueuePK WHERE TaskStatus = 'Pending')
BEGIN
    BEGIN TRANSACTION;

    -- Извлекаем следующую задачу из очереди
    SELECT TOP 1 
        @TaskId = Id,
        @SchemaName = SchemaName,
        @TableName = TableName
    FROM DBA..QueuePK
    WHERE TaskStatus = 'Pending'
    ORDER BY Id;

    -- Обновляем статус задачи на Processing
    UPDATE DBA..QueuePK
    SET TaskStatus = 'Processing', LastUpdateTime = GETDATE()
    WHERE Id = @TaskId;

    COMMIT TRANSACTION;

    BEGIN TRY
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

        -- Обновляем статус задачи на Completed
        UPDATE DBA..QueuePK
        SET TaskStatus = 'Completed', LastUpdateTime = GETDATE()
        WHERE Id = @TaskId;
    END TRY
    BEGIN CATCH
        -- В случае ошибки фиксируем в статусе
        UPDATE DBA..QueuePK
        SET TaskStatus = 'Error', LastUpdateTime = GETDATE()
        WHERE Id = @TaskId;

        PRINT ERROR_MESSAGE();
    END CATCH;
END;
