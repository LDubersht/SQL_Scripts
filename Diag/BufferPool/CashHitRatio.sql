SELECT 
    (CASE WHEN [Buffer Cache Hit Ratio] IS NULL 
          THEN 0 
          ELSE [Buffer Cache Hit Ratio]
     END) AS [Buffer Cache Hit Ratio]
FROM 
    (SELECT 
         CAST(ROUND(100.0 * (1 - (CAST(SUM(total_physical_reads) AS FLOAT) / 
                                   CAST(SUM(total_logical_reads) AS FLOAT))), 2) AS DECIMAL(5,2)) AS [Buffer Cache Hit Ratio]
     FROM sys.dm_exec_query_stats
    ) AS [Buffer Cache Hit Ratio];