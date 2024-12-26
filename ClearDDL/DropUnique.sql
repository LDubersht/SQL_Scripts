DECLARE @SQL NVARCHAR(MAX);

-- Generate the DROP CONSTRAINT statements for UNIQUE constraints
SELECT @SQL = STRING_AGG(
    'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + 
    ' DROP CONSTRAINT ' + QUOTENAME(c.name), 
    '; ')
FROM sys.objects c
INNER JOIN sys.tables t ON c.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE c.type = 'UQ'; -- 'UQ' stands for UNIQUE constraints

-- Execute the generated SQL
IF @SQL IS NOT NULL
BEGIN
    PRINT @SQL; -- Optional: Review the SQL before execution
    EXEC sp_executesql @SQL;
END
ELSE
BEGIN
    PRINT 'No UNIQUE constraints found to drop in the database.';
END;
