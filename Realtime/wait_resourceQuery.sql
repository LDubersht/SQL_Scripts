SELECT DMF.*
FROM sys.dm_exec_requests AS DM  
CROSS APPLY sys.fn_PageResCracker (DM.page_resource) AS  fn 
CROSS APPLY sys.dm_db_page_info(fn.db_id, fn.file_id, fn.page_id, 'Detailed') AS DMF