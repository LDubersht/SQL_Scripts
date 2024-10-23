-- Start Transaction in Session 1
BEGIN TRANSACTION;

-- Step 1: Lock the page that contains the row with ID = 1
UPDATE TestTableHeap WITH (PAGLOCK) SET Data = 'Z' WHERE ID = 1;

-- Simulate delay to allow the second transaction to proceed
WAITFOR DELAY '00:00:05';

-- Step 2: Try to lock another page
UPDATE TestTableHeap WITH (PAGLOCK) SET Data = 'X' WHERE ID = 5;

-- Don't commit yet, holding the transaction
