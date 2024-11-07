SELECT TOP 50 query_stats.query_hash AS Query_Hash,   
    MIN(query_stats.statement_text) AS Sample_Statement_Text,
	MAX(query_stats.creation_time) AS PlanCreationTime,
     SUM(query_stats.execution_count) AS ExecutionCount,
     SUM(query_stats.total_worker_time) /  SUM(query_stats.execution_count)/1000 AS AvgCPUTimeMS,
     SUM(query_stats.total_elapsed_time) /  SUM(query_stats.execution_count)/1000 AS AvgElapsedTime,
     SUM(query_stats.total_logical_reads) /  SUM(query_stats.execution_count) AS AvgLogicalReads,
     SUM(query_stats.total_logical_writes) /  SUM(query_stats.execution_count) AS AvgLogicalWrites,
     SUM(query_stats.total_physical_reads) /  SUM(query_stats.execution_count) AS AvgPhysicalReads,
     SUM(query_stats.total_worker_time) AS TotalCPUTime,
     SUM(query_stats.total_elapsed_time) AS TotalElapsedTime,
	 MAX(query_stats.last_execution_time) as LastExecutionTime,
	 MAX(query_stats.last_rows) as LastRows
FROM   
    (SELECT QS.*,   
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  
    ((CASE statement_end_offset   
        WHEN -1 THEN DATALENGTH(ST.text)  
        ELSE QS.statement_end_offset END   
            - QS.statement_start_offset)/2) + 1) AS statement_text  
     FROM sys.dm_exec_query_stats AS QS  
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats 
WHERE query_stats.last_execution_time > '2024-11-07 09:00:00' AND query_stats.total_elapsed_time / query_stats.execution_count > 1000000
GROUP BY query_stats.query_hash  
ORDER BY 5 DESC;  