DECLARE @resource_description VARCHAR(100) = 'PAGE: 6:1:400';

-- Переменные для хранения частей строки
DECLARE @resource_type VARCHAR(50);
DECLARE @database_id INT;
DECLARE @file_id INT;
DECLARE @page_id INT;

-- Извлечение значений из строки
SET @resource_type = LEFT(@resource_description, CHARINDEX(':', @resource_description) - 1);

SET @database_id = CAST(SUBSTRING(
    @resource_description,
    CHARINDEX(':', @resource_description) + 2,
    CHARINDEX(':', @resource_description, CHARINDEX(':', @resource_description) + 1) - CHARINDEX(':', @resource_description) - 2
) AS INT);

SET @file_id = CAST(SUBSTRING(
    @resource_description,
    CHARINDEX(':', @resource_description, CHARINDEX(':', @resource_description) + 1) + 1,
    CHARINDEX(':', @resource_description, CHARINDEX(':', @resource_description, CHARINDEX(':', @resource_description) + 1) + 1) - CHARINDEX(':', @resource_description, CHARINDEX(':', @resource_description) + 1) - 1
) AS INT);

SET @page_id = CAST(RIGHT(@resource_description, LEN(@resource_description) - CHARINDEX(':', @resource_description, CHARINDEX(':', @resource_description, CHARINDEX(':', @resource_description) + 1) + 1)) AS INT);

-- Проверка результатов
SELECT 
    @resource_type AS ResourceType,
    @database_id AS DatabaseID,
    @file_id AS FileID,
    @page_id AS PageID;

--DECLARE @database_id INT = 6;
--DECLARE @file_id INT = 1; 
--DECLARE @page_id INT = 400;



SELECT
    OBJECT_NAME(p.[OBJECT_ID], @database_id) AS table_name,
    i.name AS index_name,
    -- Используем другие столбцы из sys.dm_db_page_info
    STUFF((
        SELECT ', ' + c.name
        FROM sys.columns c
        WHERE c.object_id = p.object_id
		AND c.column_id = ic.column_id 
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS index_column_names
FROM sys.dm_db_page_info(@database_id, @file_id, @page_id, 'DETAILED') p
LEFT JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
LEFT JOIN sys.index_columns ic ON ic.index_id = i.index_id and ic.[object_id] = i.[object_id]


SELECT 
    sys.fn_PhysLocFormatter (%%physloc%%),
    *
FROM TestTableHeap (NOLOCK)
WHERE sys.fn_PhysLocFormatter (%%physloc%%) like '(1:408%'
GO
--Decode the database_id

SELECT 
    name 
FROM sys.databases 
WHERE database_id=6;
GO

--Look up the data file name for the database
SELECT 
    name, 
    physical_name
FROM sys.database_files
--WHERE file_id = 3;
GO

/* This trace flag makes DBCC PAGE output go to our Messages tab
instead of the SQL Server Error Log file */
DBCC TRACEON (3604);
GO

/* DBCC PAGE (DatabaseName, FileId, PageNumber, DumpStyle)*/
DBCC PAGE ('Test',1,408,2);
GO

DBCC TRACEOFF (3604)

SELECT OBJECT_SCHEMA_NAME(pg.object_id) AS schema_name,  
           OBJECT_NAME(pg.object_id) AS object_name,  
           i.name AS index_name,  
           p.partition_number  
    FROM sys.dm_db_page_info(DB_ID(), 1, 408, default) AS pg  
    INNER JOIN sys.indexes AS i  
    ON pg.object_id = i.object_id  
       AND  
       pg.index_id = i.index_id  
    INNER JOIN sys.partitions AS p  
    ON pg.partition_id = p.partition_id;  


	SELECT b.name AS TableName, 
       c.name AS IndexName, c.type_desc AS IndexType, * 
FROM sys.partitions a
INNER JOIN sys.objects b 
   ON a.object_id = b.object_id
INNER JOIN sys.indexes c 
   ON a.object_id = c.object_id  AND a.index_id = c.index_id
WHERE partition_id IN ('72057594043760640')


GO
SELECT 
    sys.fn_PhysLocFormatter (%%physloc%%),
    *
FROM TestTableHeap (NOLOCK)
WHERE sys.fn_PhysLocFormatter (%%physloc%%) like '(1:408%'
GO

