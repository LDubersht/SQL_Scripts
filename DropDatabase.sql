DECLARE @SQL nvarchar(1000);
DECLARE @DB_Name nvarchar(128);;
SET @DB_Name = 'gp_agents'
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = @DB_Name)
BEGIN
    SET @SQL = N'USE ['+@DB_Name+'];

                 ALTER DATABASE '+@DB_Name+' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                 USE [master];

                 DROP DATABASE '+@DB_Name+';';
    EXEC (@SQL);
END;
GO
