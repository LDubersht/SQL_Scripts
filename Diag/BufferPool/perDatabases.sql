SELECT 
    CASE 
        WHEN database_id = 32767 THEN 'Resource Database' 
        ELSE DB_NAME(database_id) 
    END AS DatabaseName,
    COUNT(*) * 8 / 1024 AS CachedSizeMB
FROM 
    sys.dm_os_buffer_descriptors
GROUP BY 
    database_id
ORDER BY 
    CachedSizeMB DESC;
