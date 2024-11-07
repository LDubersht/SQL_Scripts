
DECLARE @resource_description VARCHAR(100) = 'PAGE: 6:1:59370594'

;WITH deadlock_events AS (
    SELECT 
        xed.value('@timestamp', 'datetime2(3)') as creation_time,
        xed.query('.') as deadlock_graph
    FROM (
        SELECT CAST(target_data as XML) as target_data
        FROM sys.dm_xe_session_targets xst
        JOIN sys.dm_xe_sessions xs ON xs.address = xst.event_session_address
        WHERE xs.name = 'system_health'
        AND xst.target_name = 'ring_buffer'
    ) as xml_data
    CROSS APPLY target_data.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]/data/value') AS XEventData(xed)
    WHERE xed.value('(/deadlock/resource-list/resource/@process-duration)[1]', 'int') > 0
)
SELECT 
    deadlock_graph,
    creation_time
FROM deadlock_events
ORDER BY creation_time DESC
OFFSET 0 ROWS
FETCH FIRST 1 ROW ONLY;
