SELECT 
    blocking_request.blocking_session_id AS BlockingSessionID,
    blocking_request.[session_id] AS BlockingSessionID,
    blocking_request.status AS BlockingStatus,
    blocking_request.command AS BlockingCommand,
    blocked_request.[session_id] AS BlockedSessionID,
    blocked_request.status AS BlockedStatus,
    blocked_request.command AS BlockedCommand,
    blocked_request.blocking_session_id AS BlockedBySessionID,
    blocked_request.cpu_time AS BlockedCPUTime,
    blocked_request.total_elapsed_time AS BlockedElapsedTime,
    blocked_request.database_id AS BlockedDatabaseID,
    blocked_request.wait_type AS BlockedWaitType,
    blocked_request.wait_time AS BlockedWaitTime,
    blocked_request.blocking_session_id AS BlockedBySessionID,
	blocked_request.wait_time AS [blocked_request.wait_tim],
	blocked_request.last_wait_type AS [blocked_request.last_wait_type],
	blocked_request.wait_resource AS [blocked_request.wait_resource],
	blocking_request.query_plan_hash AS [blocking_request.query_plan_hash],
	blocking_request.statement_sql_handle AS [blocking_request.statement_sql_handle],
	blocking_request.statement_context_id AS [blocking_request.statement_context_id],
	blocked_request.query_plan_hash AS [blocked_request.query_plan_hash],
	blocked_request.statement_sql_handle AS [blocked_request.statement_sql_handle],
	blocked_request.statement_context_id AS [blocked_request.statement_context_id] 
FROM 
    sys.dm_exec_requests AS blocked_request
LEFT JOIN 
    sys.dm_exec_sessions AS blocking_session
    ON blocked_request.blocking_session_id = blocking_session.session_id
LEFT JOIN 
    sys.dm_exec_requests AS blocking_request
    ON blocking_session.session_id = blocking_request.session_id
WHERE 
    blocked_request.blocking_session_id <> 0;
