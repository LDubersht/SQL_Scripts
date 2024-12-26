DECLARE @SQL NVARCHAR(MAX);

-- Generate a list of foreign key drop statements
SELECT @SQL = STRING_AGG('ALTER TABLE ' + cast(QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) as NVARCHAR(MAX)) + '.' + 
                         QUOTENAME(OBJECT_NAME(parent_object_id)) +
                         ' DROP CONSTRAINT ' + QUOTENAME(name), '; ')
FROM sys.foreign_keys;

-- Execute the generated SQL
IF @SQL IS NOT NULL
BEGIN
    PRINT @SQL; -- Optional: Review the SQL before execution
    EXEC sp_executesql @SQL;
END
ELSE
BEGIN
    PRINT 'No foreign keys found in the database.';
END;
