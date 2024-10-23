--RID: 15:15:11695844:3
/* Break apart my RID into it's individual sections */
DECLARE @db_id SMALLINT = 15;
DECLARE @file_id SMALLINT = 15;
DECLARE @page_id INT = 11695844;
DECLARE @index_id SMALLINT = 3;
DECLARE @db_name VARCHAR(256) = (SELECT DB_NAME(@db_id))


/* Create and populate a temp table with the meta data from that data page */
CREATE TABLE #PageResults
( [ParentObject] NVARCHAR(255), [Object] NVARCHAR(255), [Field] NVARCHAR(255), [VALUE] NVARCHAR(255) );
INSERT INTO #PageResults
( ParentObject, [Object], Field, [VALUE] )
EXECUTE ('DBCC PAGE (' + @db_id + ', ' + @file_id + ', ' + @page_id + ', 0) WITH TABLERESULTS;');


/* Tie the metadata in the dbcc page output and give me my resource */
EXECUTE ('
SELECT sc.name AS schema_name,
so.name AS object_name,
si.name AS index_name
FROM ' + @db_name + '.sys.partitions AS p
INNER JOIN ' + @db_name + '.sys.objects AS so
ON p.object_id = so.object_id
INNER JOIN ' + @db_name + '.sys.indexes AS si
ON p.index_id = si.index_id
AND p.object_id = si.object_id
INNER JOIN ' + @db_name + '.sys.schemas AS sc
ON so.schema_id = sc.schema_id
INNER JOIN #PageResults pr
ON so.object_id = pr.[VALUE]
WHERE si.index_id = ' + @index_id + '
AND Field = ''Metadata: ObjectId'';
')