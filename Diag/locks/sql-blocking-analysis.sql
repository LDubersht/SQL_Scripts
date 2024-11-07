-- Детальный анализ текущих блокировок с информацией о запросах
SELECT 
    -- Заблокированный процесс
    spid = session_id,
    -- Блокирующий процесс
    blocking_session_id,
    -- Длительность блокировки
    CAST(ROUND(wait_time / 1000.0, 2) AS DECIMAL(10,2)) AS wait_time_seconds,
    -- Тип ресурса
    wait_type,
    -- Текст запроса заблокированного процесса
    sql_text = (
        SELECT text 
        FROM sys.dm_exec_sql_text(sql_handle)
    ),
    -- База данных
    DB_NAME(database_id) AS database_name,
    -- Программа
    program_name = s.program_name,
    -- Имя хоста
    host_name = s.host_name,
    -- Имя пользователя
    login_name = s.login_name,
    -- Статус
    status = r.status,
    -- Время старта запроса
    start_time = r.start_time,
    -- Тип команды
    command = r.command
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
WHERE r.blocking_session_id != 0
ORDER BY wait_time DESC;

-- Просмотр блокирующего дерева (кто кого блокирует)
;WITH BlockingHierarchy (
    blocking_session_id,
    session_id,
    wait_type,
    wait_duration_ms,
    blocking_level,
    complete_chain
)
AS (
    -- Anchor член (корневые блокировки)
    SELECT 
        blocking_session_id,
        session_id,
        wait_type,
        wait_duration_ms,
        0 AS blocking_level,
        CAST(CONVERT(VARCHAR(30), session_id) AS VARCHAR(1000)) AS complete_chain
    FROM sys.dm_exec_requests
    WHERE blocking_session_id = 0
        AND session_id IN (SELECT blocking_session_id FROM sys.dm_exec_requests)
    
    UNION ALL
    
    -- Рекурсивный член (заблокированные процессы)
    SELECT 
        der.blocking_session_id,
        der.session_id,
        der.wait_type,
        der.wait_duration_ms,
        bh.blocking_level + 1 AS blocking_level,
        CAST(bh.complete_chain + ' -> ' + CONVERT(VARCHAR(30), der.session_id) AS VARCHAR(1000)) AS complete_chain
    FROM sys.dm_exec_requests der
    INNER JOIN BlockingHierarchy bh ON der.blocking_session_id = bh.session_id
)
SELECT 
    bh.*,
    ses.login_name,
    ses.host_name,
    ses.program_name,
    CAST(deqp.query_plan AS XML) AS query_plan,
    dest.text AS sql_text
FROM BlockingHierarchy bh
LEFT JOIN sys.dm_exec_sessions ses ON bh.session_id = ses.session_id
OUTER APPLY sys.dm_exec_query_plan(
    (SELECT plan_handle 
     FROM sys.dm_exec_requests 
     WHERE session_id = bh.session_id)
) deqp
OUTER APPLY sys.dm_exec_sql_text(
    (SELECT sql_handle 
     FROM sys.dm_exec_requests 
     WHERE session_id = bh.session_id)
) dest
ORDER BY blocking_level, session_id;

-- Быстрый просмотр текущих блокировок
SELECT 
    DTL.resource_type,
    DB_NAME(DTL.resource_database_id) AS database_name,
    OBJECT_NAME(DTL.resource_associated_entity_id) AS object_name,
    DTL.request_mode,
    DTL.request_type,
    -- Блокирующая сессия
    DTL.request_session_id,
    -- Ожидающая сессия
    DTL.request_owner_type
FROM sys.dm_tran_locks as DTL
WHERE DTL.request_status = 'WAIT'
ORDER BY DTL.request_session_id;

-- Информация о deadlocks из кольцевого буфера
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
ORDER BY creation_time DESC;
