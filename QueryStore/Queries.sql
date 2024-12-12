WITH QueryExecutionCounts AS (
    SELECT 
        qp.last_execution_time,
		qp.last_compile_start_time,
        rs.count_executions,
        qt.query_sql_text,
        LEN(qt.query_sql_text) AS sql_length,
        rs.avg_duration,
        rs.max_rowcount,
        rs.avg_rowcount,
        rs.last_rowcount
    FROM 
        sys.query_store_plan qp
        INNER JOIN sys.query_store_query q ON qp.query_id = q.query_id
        INNER JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
        INNER JOIN sys.query_store_runtime_stats rs ON qp.plan_id = rs.plan_id
		INNER JOIN sys.query_store_runtime_stats_interval rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
	WHERE 
	    rsi.start_time > '2024-12-01'

)
SELECT TOP 1000
    query_sql_text,
    sum(count_executions) AS execution_count,
    MAX(last_execution_time) AS last_execution_time,
	MAX(last_compile_start_time) as last_compile_start_time,
    MAX(avg_duration) AS avg_duration,
    MAX(sql_length) AS sql_length,
    MAX(max_rowcount) AS max_rowcount,
    MAX(avg_rowcount) AS avg_rowcount,
    MAX(last_rowcount) AS last_rowcount
FROM 
    QueryExecutionCounts
GROUP BY 
    query_sql_text
ORDER BY 
    execution_count DESC;
