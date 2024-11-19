SELECT 
    DB_NAME(database_id) AS DatabaseName,
    name AS LogicalFileName,
    physical_name AS PhysicalFilePath,
    size * 8 / 1024 AS FileSizeMB
FROM 
    sys.master_files
ORDER BY 
 FileSizeMB DESC;