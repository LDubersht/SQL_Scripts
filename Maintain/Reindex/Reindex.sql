DROP TABLE IF EXISTS #ListIndexes
DECLARE @dbName NVARCHAR(128)
SET @dbName = DB_NAME();  -- Current database

DECLARE @fragmentationThreshold FLOAT,@rebuildThreshold FLOAT
SET @fragmentationThreshold = 5.0  -- Threshold fragmentation in percent
SET @rebuildThreshold = 10.0 -- Threshold rebuild percent

DECLARE @schemaName NVARCHAR(128)
DECLARE @tableName NVARCHAR(128)
DECLARE @indexName NVARCHAR(128)
DECLARE @fragmentation FLOAT
DECLARE @sql NVARCHAR(MAX)

    SELECT 
        dbschemas.name AS SchemaName,
        dbtables.name AS TableName,
        dbindexes.name AS IndexName,
        indexstats.index_id AS IndexID,
        indexstats.avg_fragmentation_in_percent AS Fragmentation
		INTO #ListIndexes
    FROM 
        sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') AS indexstats
        INNER JOIN sys.tables dbtables ON dbtables.[object_id] = indexstats.[object_id]
        INNER JOIN sys.schemas dbschemas ON dbtables.[schema_id] = dbschemas.[schema_id]
        INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
        AND indexstats.index_id = dbindexes.index_id
    WHERE 
        indexstats.avg_fragmentation_in_percent > @fragmentationThreshold
    ORDER BY indexstats.avg_fragmentation_in_percent

-- Get index more than fragmentation threshold
DECLARE index_cursor CURSOR FOR
SELECT 
    SchemaName, 
    TableName, 
    IndexName, 
    Fragmentation 
FROM 
    #ListIndexes
order by SchemaName, 
    TableName, 
    IndexName 

OPEN index_cursor

FETCH NEXT FROM index_cursor INTO @schemaName, @tableName, @indexName, @fragmentation

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'ALTER INDEX [' + @indexName + '] ON [' + @schemaName + '].[' + @tableName + '] ' +
               CASE 
                   WHEN @fragmentation > @rebuildThreshold THEN 'REBUILD;' 
                   ELSE 'REORGANIZE;' 
               END
    
	print @sql
    --EXEC sp_executesql @sql

    FETCH NEXT FROM index_cursor INTO @schemaName, @tableName, @indexName, @fragmentation
END

CLOSE index_cursor
DEALLOCATE index_cursor
