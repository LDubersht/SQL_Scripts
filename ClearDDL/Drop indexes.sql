DECLARE @SQL NVARCHAR(MAX);

-- Generate DROP INDEX statements for all indexes including primary keys
SELECT @SQL = STRING_AGG(
	CAST(CASE 
        WHEN i.is_primary_key = 1 THEN 
            'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + 
            ' DROP CONSTRAINT ' + QUOTENAME(i.name)
        ELSE 
            'DROP INDEX ' + QUOTENAME(i.name) + 
            ' ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
		END AS NVARCHAR(MAX)), 
    '; ')
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.type IN (1, 2) -- 1 = clustered, 2 = non-clustered
  AND i.is_unique_constraint = 0; -- Exclude unique constraints

-- Execute the generated SQL
IF @SQL IS NOT NULL
BEGIN
    --PRINT @SQL; -- Optional: Review the SQL before execution
    EXEC sp_executesql @SQL;
END
ELSE
BEGIN
    PRINT 'No indexes found to drop in the database.';
END;
