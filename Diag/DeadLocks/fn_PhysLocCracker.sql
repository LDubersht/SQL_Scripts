SELECT page_info.* 
FROM sys.fn_PageResCracker (d.page_resource) AS r  
CROSS APPLY sys.dm_db_page_info(r.db_id, r.file_id, r.page_id, 'DETAILED') AS page_info


SELECT OBJECT_SCHEMA_NAME(pg.object_id) AS schema_name,  
           OBJECT_NAME(pg.object_id) AS object_name,  
           i.name AS index_name,  
           p.partition_number  
    FROM sys.dm_db_page_info(DB_ID(), 1, 408, default) AS pg  
    INNER JOIN sys.indexes AS i  
    ON pg.object_id = i.object_id  
       AND  
       pg.index_id = i.index_id  
    INNER JOIN sys.partitions AS p  
    ON pg.partition_id = p.partition_id;  


