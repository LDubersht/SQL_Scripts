declare @databaseName varchar(100) = 'yourdatabaseName' --CHANGE HERE !
declare @keyValue varchar(100) = 'KEY: 9:72057632651542528 (543066506c7c)' --Output from deadlock graph -- CHANGE HERE !
declare @lockres varchar(100)
declare @hobbitID bigint

select @hobbitID = convert(bigint, RTRIM(SUBSTRING(@keyValue, CHARINDEX(':', @keyValue, CHARINDEX(':', @keyValue) + 1) + 1, CHARINDEX('(', @keyValue) - CHARINDEX(':', @keyValue, CHARINDEX(':', @keyValue) + 1) - 1)))

select @lockRes = RTRIM(SUBSTRING(@keyValue, CHARINDEX('(', @keyValue) + 1, CHARINDEX(')', @keyValue) - CHARINDEX('(', @keyValue) - 1))

declare @objectName sysname
declare @ObjectLookupSQL as nvarchar(max) = '
SELECT @objectName = o.name
FROM ' + quotename(@databaseName) + '.sys.partitions p
JOIN ' + quotename(@databaseName) + '.sys.indexes i ON p.index_id = i.index_id AND p.[object_id] = i.[object_id]
join ' + quotename(@databaseName)+ '.sys.objects o on o.object_id = i.object_id
WHERE hobt_id = ' + convert(nvarchar(50), @hobbitID) + ''

--print @ObjectLookupSQL
exec sp_executesql @ObjectLookupSQL
    ,N'@objectName sysname OUTPUT'
    ,@objectName = @objectName output

--print @objectName

declare @finalResult nvarchar(max) = N'select %%lockres%% ,* 
from ' + quotename(@databaseName) + '.dbo.' + @objectName + '
where %%lockres%% = ''(' + @lockRes + ')''
'
--print @finalresult
exec sp_executesql @finalResult


-- Given: KEY: 9:72057632651542528 (543066506c7c)
-- and object = MyDatabase.MySchema.MyTable

DECLARE 
  @hobt BIGINT = 72057632651542528,
  @db SYSNAME = DB_NAME(9),
  @res VARCHAR(255) = '(543066506c7c)';

DECLARE @exec NVARCHAR(MAX) = QUOTENAME(@db) + N'.sys.sp_executesql';

DECLARE @sql NVARCHAR(MAX) = N'SELECT %%LOCKRES%%,*
  FROM MySchema.MyTable WHERE %%LOCKRES%% = @res;';

EXEC @exec @sql, N'@res VARCHAR(255)', @res;