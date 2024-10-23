-- Start Transaction in Session 2
BEGIN TRANSACTION;

-- Step 1: Lock the page that contains the row with ID = 5
UPDATE TestTableHeap WITH (PAGLOCK) SET Data = 'Y' WHERE ID = 5;

-- Simulate delay to allow the first transaction to proceed
WAITFOR DELAY '00:00:05';

-- Step 2: Try to lock another page
UPDATE TestTableHeap WITH (PAGLOCK) SET Data = 'W' WHERE ID = 1;

-- Don't commit yet, holding the transaction
