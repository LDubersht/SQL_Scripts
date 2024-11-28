DECLARE @Excludes varchar(8000) = 'TestTable' --table name to exclude ([<schema>].[<table>],[<schema>].[<table>] only!)
, @ThresholdFullU  bigint = 10000000 --threshold row count to change full update to partial (count rows)
, @ThresholdPercent tinyint = 15 --minimum percent to partial update

SET NOCOUNT ON
DECLARE 
@schemaname NVARCHAR(128),
@tablename NVARCHAR(128),
@cmd NVARCHAR(300),
@cnt bigint,
@Percent tinyint,
@t datetime  

DECLARE updatestats CURSOR FOR
SELECT 
	ist.TABLE_SCHEMA,ist.TABLE_NAME 
FROM 
	information_schema.tables ist
LEFT JOIN
	string_split( @Excludes,',') e
	ON e.[value] = QUOTENAME(ist.TABLE_SCHEMA) + '.' + QUOTENAME(ist.TABLE_NAME )
WHERE TABLE_TYPE = 'BASE TABLE' 
AND e.[value] IS NULL 
ORDER BY TABLE_SCHEMA,TABLE_NAME
OPEN updatestats

FETCH NEXT FROM updatestats INTO @schemaname, @tablename
WHILE (@@FETCH_STATUS = 0)
BEGIN
	PRINT 'UPDATING: ' + QUOTENAME(@schemaname) + '.' + QUOTENAME(@tablename)
	
	SET @cmd = 'SET @cnt = (SELECT COUNT(*) FROM '+ QUOTENAME(@schemaname) + '.' + QUOTENAME(@tablename) + ')'
	EXEC sp_executesql @cmd,N'@cnt bigint OUT', @cnt OUT

	PRINT 'Count:' + CAST(@cnt AS varchar(20))
	IF @cnt < @ThresholdFullU
	BEGIN
		SET @cmd = 'UPDATE STATISTICS '  + QUOTENAME(@schemaname) + '.' + QUOTENAME(@tablename) + ' 
		WITH FULLSCAN;'
	END
	ELSE
	BEGIN
		SET @Percent = IIF(@ThresholdFullU*100/@cnt<10, 10,(Round(@ThresholdFullU*100/@cnt,0)))
		SET @cmd = 'UPDATE STATISTICS '  + QUOTENAME(@schemaname) + '.' + QUOTENAME(@tablename) + ' 
		WITH SAMPLE ' + CAST(@Percent AS varchar(16))  + ' PERCENT;'
		PRINT @cmd
	END
	SET @t = getdate()
	EXEC sp_executesql @cmd
	PRINT 'ExecTime(ms):' + CAST(datediff(ms,@t,getdate()) AS VARCHAR(20))

   FETCH NEXT FROM updatestats INTO @schemaname,@tablename
END

CLOSE updatestats
DEALLOCATE updatestats
GO
SET NOCOUNT OFF
GO