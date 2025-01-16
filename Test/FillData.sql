

-- Процедура для создания таблицы и заполнения её данными
CREATE OR ALTER PROCEDURE CreateAndFillTable
    @TableName NVARCHAR(128),
    @RowCount BIGINT
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @i int = 0
	SET @RowCount = CAST(@RowCount / 10 AS INT)
    -- Создание таблицы
    SET @SQL = 'CREATE TABLE ' + @TableName + ' (
        ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100),
        Value INT,
        Description NVARCHAR(2000)
    );';
    EXEC sp_executesql @SQL;
    
    -- Заполнение таблицы данными
    SET @SQL = 'WITH 
     t10 AS (SELECT n FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) t(n))
    ,t1k AS (SELECT 0 AS n FROM t10 AS a CROSS JOIN t10 AS b CROSS JOIN t10 AS c)
    ,t1kkk AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS n FROM t1k AS a CROSS JOIN t1k AS b CROSS JOIN t1k AS c)
                INSERT INTO ' + @TableName + ' (Name, Value, Description)
                SELECT TOP '+CAST(@RowCount AS NVARCHAR)+'
                    LEFT(REPLICATE(LEFT(NEWID(), 36),3),100) AS Name, 
                    ABS(CHECKSUM(NEWID()) % 1000000) AS Value,
                    REPLICATE(LEFT(NEWID(), 36),55) AS Description
                FROM t1kkk;';
	WHILE @i<10
	BEGIN
		EXEC sp_executesql @SQL;
		SET @I = @i +1
	END
END;
GO

DECLARE @TableName NVARCHAR(128);
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN
	SET @TableName = 'Table_' + CAST(@i AS NVARCHAR)
	IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME  = @TableName)
		EXEC CreateAndFillTable @TableName, 10000000;
    SET @i = @i + 1;
END;
GO

