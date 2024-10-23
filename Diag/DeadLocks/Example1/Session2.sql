BEGIN TRANSACTION;
    -- Step 1: Transaction B locks Table2
    UPDATE Table2 SET ID = 1 WHERE ID = 1;
    
    -- Step 2: Transaction B waits for a lock on Table1
    WAITFOR DELAY '00:00:05';  -- Simulates some delay
    UPDATE Table1 SET ID = 1 WHERE ID = 1;

-- Don't commit yet; holding the transaction open
