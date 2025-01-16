

CREATE OR ALTER PROCEDURE sp_CreateTableText
	@DatabaseName NVARCHAR(255), 
	@SchemaName NVARCHAR(255), 
	@TableName NVARCHAR(255), 
	@Script  NVARCHAR(MAX) OUT
AS

DECLARE @CreateTableSQL NVARCHAR(MAX) = 'CREATE TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + '] (' + CHAR(13),
	@CreateFields NVARCHAR(max) = '',
	@sql NVARCHAR(max);
SET @sql = 'SELECT @CreateFields = @CreateFields + 
    ''    ['' + COLUMN_NAME + ''] '' + 
    DATA_TYPE + 
    CASE 
        WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN ''('' + 
            CASE 
                WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN ''MAX'' 
                ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) 
            END + '')''
        ELSE ''''
    END + 
    CASE 
        WHEN IS_NULLABLE = ''NO'' THEN '' NOT NULL'' 
        ELSE '' NULL''
    END + '','' + CHAR(13)
FROM ['+@DatabaseName+'].INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '''+@TableName+'''
AND TABLE_SCHEMA = '''+@SchemaName+'''
ORDER BY ORDINAL_POSITION;'
EXEC sp_executeSQL @sql, N'@CreateFields NVARCHAR(max) OUT',@CreateFields OUT
SET @CreateTableSQL = @CreateTableSQL + @CreateFields
-- Remove the last comma and add closing bracket
SET @CreateTableSQL = LEFT(@CreateTableSQL, LEN(@CreateTableSQL) - 2) + CHAR(13) + ')';
-- Output the create table statement
SET @Script = @CreateTableSQL;