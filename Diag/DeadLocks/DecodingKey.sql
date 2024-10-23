declare @databaseName varchar(100) = 'Your Database'--DatabaseName

declare @keyValue varchar(100) = 'KEY: 6:72057594043891712 (8194443284a0)'--Output from deadlock graph

declare @lockres varchar(100)

declare @hobbitID bigint

select @hobbitID = convert(bigint,RTRIM(SUBSTRING(@keyValue,CHARINDEX(':',@keyValue,CHARINDEX(':',@keyValue)+1)+1,

CHARINDEX('(',@keyValue)-CHARINDEX(':',@keyValue,CHARINDEX(':',@keyValue)+1)-1)))

select @lockRes = RTRIM(SUBSTRING(@keyValue,CHARINDEX('(',@keyValue)+1,CHARINDEX(')',@keyValue)-CHARINDEX('(',@keyValue)-1))

declare @objectName sysname

declare @ObjectLookupSQL as nvarchar(max) = '

SELECT @objectName = o.name

FROM '+@databaseName+'.sys.partitions p

JOIN '+@databaseName+'.sys.indexes i ON p.index_id = i.index_id AND p.[object_id] = i.[object_id]

join '+@databaseName+'.sys.objects o on o.object_id = i.object_id

WHERE hobt_id = '+convert(nvarchar(50),@hobbitID)+'

'

exec sp_executesql @ObjectLookupSQL, N'@objectName sysname OUTPUT',@objectName=@objectName OUTPUT

select @objectName

declare @finalResult nvarchar(max) = N'select %%lockres%% ,*

from '+@databaseName+'.dbo.' + @objectName + '

where %%lockres%% = ''('+@lockRes+')''

'

exec sp_executesql @finalResult


	SELECT 
   sys.fn_PhysLocFormatter(%%physloc%%) AS PageResource, 
   %%lockres%% AS LockResource, *
FROM TestTableHeap
WHERE %%lockres%% IN ('(8194443284a0)')


