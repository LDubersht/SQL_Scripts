BEGIN TRANSACTION;
    -- Step 1: Transaction A locks Table1
    UPDATE Table1 SET ID = 1 WHERE ID = 1;
    
    -- Step 2: Transaction A waits for a lock on Table2
    WAITFOR DELAY '00:00:05';  -- Simulates some delay
    UPDATE Table2 SET ID = 1 WHERE ID = 1;
    
-- Don't commit yet; holding the transaction open
