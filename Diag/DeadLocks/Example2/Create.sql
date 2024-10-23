DROP TABLE IF EXISTS TestTableHeap
CREATE TABLE TestTableHeap (
    ID INT PRIMARY KEY NONCLUSTERED,
    Data NVARCHAR(100)
);

-- Insert sufficient data to spread across multiple pages
INSERT INTO TestTableHeap (ID, Data)
VALUES (1, REPLICATE('A', 100)), (2, REPLICATE('B', 100)),
       (3, REPLICATE('C', 100)), (4, REPLICATE('D', 100)),
       (5, REPLICATE('E', 100)), (6, REPLICATE('F', 100)),
       (7, REPLICATE('G', 100)), (8, REPLICATE('H', 100)),
       (9, REPLICATE('I', 100)), (10, REPLICATE('J', 100));
