CREATE TABLE #errorlog (
            LogDate DATETIME 
            , ProcessInfo VARCHAR(100)
            , [Text] VARCHAR(MAX)
            );
DECLARE @tag VARCHAR (MAX) , @path VARCHAR(MAX);
INSERT INTO #errorlog EXEC sp_readerrorlog;
SELECT @tag = text
FROM #errorlog 
WHERE [Text] LIKE 'Logging%MSSQL\Log%';
DROP TABLE IF EXISTS #errorlog


SET @path = SUBSTRING(@tag, 38, CHARINDEX('MSSQL\Log', @tag) - 29);
SELECT 
  CONVERT(xml, event_data).query('/event/data/value/child::*') AS DeadlockReport,
  CONVERT(xml, event_data).value('(event[@name="xml_deadlock_report"]/@timestamp)[1]', 'datetime') 
  AS Execution_Time
FROM sys.fn_xe_file_target_read_file(@path + '\system_health*.xel', NULL, NULL, NULL)
WHERE OBJECT_NAME like 'xml_deadlock_report';




	SELECT XEvent.query('(event/data/value/deadlock)[1]') AS DeadlockGraph
FROM (
    SELECT XEvent.query('.') AS XEvent
    FROM (
        SELECT CAST(target_data AS XML) AS TargetData
        FROM sys.dm_xe_session_targets st
        INNER JOIN sys.dm_xe_sessions s 
ON s.address = st.event_session_address
        WHERE s.NAME = 'system_health'
            AND st.target_name = 'ring_buffer'
        ) AS Data
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(XEvent)
) AS source;