SELECT 
    s.[session_id],
    s.login_name,
	s.[host_name], 
    r.status,
    r.start_time,
    t.text AS query_text
FROM sys.dm_exec_sessions AS s
JOIN sys.dm_exec_requests AS r ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE s.session_id > 50 -- System session
AND s.[host_name] = '';