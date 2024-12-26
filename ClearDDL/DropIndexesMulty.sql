USE DBA
DROP TABLE IF EXISTS [Queue]
CREATE TABLE [Queue] (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName NVARCHAR(255),
    TableName NVARCHAR(255),
    IndexName NVARCHAR(255),
    TaskStatus NVARCHAR(50) DEFAULT 'Pending', -- Возможные статусы: Pending, Processing, Completed
    LastUpdateTime DATETIME DEFAULT GETDATE()
);


CREATE TABLE Log (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName NVARCHAR(255),
    TableName NVARCHAR(255),
    IndexName NVARCHAR(255),
    Status NVARCHAR(50), -- Pending, Success, Error
    Message NVARCHAR(MAX), -- Для хранения ошибок или информации
    Timestamp DATETIME DEFAULT GETDATE()
);

USE DBA
DROP TABLE IF EXISTS [Queue]
CREATE TABLE [Queue] (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SchemaName NVARCHAR(255),
    TableName NVARCHAR(255),
    IndexName NVARCHAR(255),
    TaskStatus NVARCHAR(50) DEFAULT 'Pending', -- Возможные статусы: Pending, Processing, Completed
    LastUpdateTime DATETIME DEFAULT GETDATE()
);

-- Заполнение очереди задач
INSERT INTO Queue (SchemaName, TableName, IndexName)
SELECT 
    s.name AS SchemaName, 
    t.name AS TableName, 
    i.name AS IndexName
FROM Analytics.sys.indexes i
INNER JOIN Analytics.sys.tables t ON i.object_id = t.object_id
INNER JOIN Analytics.sys.schemas s ON t.schema_id = s.schema_id
WHERE i.type IN (1, 2) -- 1 = clustered, 2 = non-clustered
  AND i.is_unique_constraint = 0 -- Exclude unique constraints;

USE Analytics

USE Analytics
DECLARE @TaskId INT;
DECLARE @SchemaName NVARCHAR(255);
DECLARE @TableName NVARCHAR(255);
DECLARE @IndexName NVARCHAR(255);
DECLARE @SQL NVARCHAR(MAX);

WHILE EXISTS (SELECT 1 FROM DBA..[Queue] WHERE TaskStatus = 'Pending')
BEGIN
    BEGIN TRANSACTION;

    -- Получаем задачу из очереди
    SELECT TOP 1 
        @TaskId = Id,
        @SchemaName = SchemaName,
        @TableName = TableName,
        @IndexName = IndexName
    FROM DBA..[Queue]
    WHERE TaskStatus = 'Pending'
    ORDER BY Id;

    -- Помечаем задачу как "Processing"
    UPDATE DBA..[Queue]
    SET TaskStatus = 'Processing', LastUpdateTime = GETDATE()
    WHERE Id = @TaskId;

    COMMIT TRANSACTION;

    -- Формируем SQL для выполнения задачи
    BEGIN TRY
        IF @IndexName IS NOT NULL
        BEGIN
            SET @SQL = CASE 
                WHEN @IndexName LIKE 'PK_%' THEN 
                    'ALTER TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + 
                    ' DROP CONSTRAINT ' + QUOTENAME(@IndexName)
                ELSE 
                    'DROP INDEX ' + QUOTENAME(@IndexName) + 
                    ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)
            END;

            EXEC sp_executesql @SQL;

            -- Логируем успешное выполнение
            INSERT INTO DBA..[Log] (SchemaName, TableName, IndexName, Status, Message)
            VALUES (@SchemaName, @TableName, @IndexName, 'Success', 'Index dropped successfully.');

            -- Обновляем статус задачи
            UPDATE DBA..Queue
            SET TaskStatus = 'Completed', LastUpdateTime = GETDATE()
            WHERE Id = @TaskId;
        END
        ELSE
        BEGIN
            -- Если задача невалидна
            INSERT INTO DBA..[Log] (SchemaName, TableName, IndexName, Status, Message)
            VALUES (@SchemaName, @TableName, NULL, 'Error', 'Invalid task, index name is NULL.');

            -- Обновляем статус задачи
            UPDATE DBA..[Queue]
            SET TaskStatus = 'Completed', LastUpdateTime = GETDATE()
            WHERE Id = @TaskId;
        END
    END TRY
    BEGIN CATCH
        -- Логируем ошибку
        INSERT INTO DBA..[Log] (SchemaName, TableName, IndexName, Status, Message)
        VALUES (@SchemaName, @TableName, @IndexName, 'Error', ERROR_MESSAGE());

        -- Обновляем статус задачи
        UPDATE DBA..Queue
        SET TaskStatus = 'Completed', LastUpdateTime = GETDATE()
        WHERE Id = @TaskId;
    END CATCH;
END;
