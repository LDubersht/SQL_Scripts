DROP TABLE IF EXISTS Products
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    CategoryID INT,
    ProductName NVARCHAR(100)
);
DROP TABLE IF EXISTS Categories
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100)
);

-- Insert sample data
INSERT INTO Products (ProductID, CategoryID, ProductName) VALUES (1, 1, 'Product A');
INSERT INTO Categories (CategoryID, CategoryName) VALUES (1, 'Category A');
GO
CREATE OR ALTER PROCEDURE UpdateProductFirst
AS
BEGIN
    BEGIN TRANSACTION;
    -- Step 1: Update Products first
    UPDATE Products SET ProductName = 'Updated Product' WHERE ProductID = 1;

    -- Simulate delay to allow the second transaction to start
    WAITFOR DELAY '00:00:05';

    -- Step 2: Update Categories
    UPDATE Categories SET CategoryName = 'Updated Category' WHERE CategoryID = 1;
    COMMIT;
END;
GO
CREATE OR ALTER PROCEDURE UpdateCategoryFirst
AS
BEGIN
    BEGIN TRANSACTION;
    -- Step 1: Update Categories first
    UPDATE Categories SET CategoryName = 'Another Category' WHERE CategoryID = 1;

    -- Simulate delay to allow the first transaction to start
    WAITFOR DELAY '00:00:05';

    -- Step 2: Update Products
    UPDATE Products SET ProductName = 'Another Product' WHERE ProductID = 1;
    COMMIT;
END;
