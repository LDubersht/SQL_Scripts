--waitresource=“PAGE: 6:1:408 " = Database_Id : FileId : PageNumber

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

