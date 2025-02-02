WITH Parents AS
(
    SELECT DISTINCT
        o.[name],
        SCHEMA_NAME(o.[schema_id]) AS [SchemaName],
        o.[type],
        o.[type_desc]
    FROM sys.objects o
    LEFT JOIN sys.sql_expression_dependencies oh ON o.[object_id] = oh.referencing_id
    WHERE oh.referencing_id IS NULL
        AND o.is_ms_shipped = 0
        AND o.type NOT IN ('S', 'IT', 'D')
),
DependencyTree AS
(
    -- Base level (direct dependencies)
    SELECT DISTINCT
        sd.referenced_database_name,
        ISNULL(sd.referenced_schema_name, 'dbo') AS referenced_schema_name, 
        sd.referenced_entity_name,
        p.[type] AS ParentType,
        p.[type_desc] AS ParentTypeDesc,
        sd.referencing_id,
        SCHEMA_NAME(cho.[schema_id]) AS ChildSchema,
        cho.[name] AS ChildEntity,
        cho.[type] AS ChildType,
        cho.[type_desc] AS ChildTypeDesc,
        CAST(p.[SchemaName] + '.' + p.[name] + ' -> ' + SCHEMA_NAME(cho.[schema_id]) + '.' + cho.[name] AS NVARCHAR(MAX)) AS Path,
        1 AS Level,
        CAST(',' + CAST(sd.referenced_id AS NVARCHAR(MAX)) + ',' AS NVARCHAR(MAX)) AS Visited
    FROM sys.sql_expression_dependencies sd
    JOIN Parents p ON sd.referenced_entity_name = p.[name] 
        AND ISNULL(sd.referenced_schema_name, 'dbo') = p.[SchemaName]
    JOIN sys.objects cho ON sd.referencing_id = cho.[object_id]
    WHERE sd.referenced_id != sd.referencing_id

    UNION ALL

    -- Recursive part
    SELECT 
        dt.referenced_database_name,
        dt.referenced_schema_name,
        dt.referenced_entity_name,
        dt.ParentType,
        dt.ParentTypeDesc,
        sd.referencing_id,
        SCHEMA_NAME(cho.[schema_id]) AS ChildSchema,
        cho.[name] AS ChildEntity,
        cho.[type] AS ChildType,
        cho.[type_desc] AS ChildTypeDesc,
        dt.Path + ' -> ' + SCHEMA_NAME(cho.[schema_id]) + '.' + cho.[name] AS Path,
        dt.Level + 1,
        CAST(dt.Visited + CAST(sd.referencing_id AS NVARCHAR(MAX)) + ',' AS NVARCHAR(MAX)) AS Visited
    FROM DependencyTree dt
    JOIN sys.sql_expression_dependencies sd ON sd.referenced_entity_name = dt.ChildEntity 
        AND ISNULL(sd.referenced_schema_name, 'dbo') = dt.ChildSchema 
    JOIN sys.objects cho ON sd.referencing_id = cho.[object_id]
    WHERE CHARINDEX(',' + CAST(sd.referencing_id AS NVARCHAR(MAX)) + ',', dt.Visited) = 0
        AND 
		dt.Level < 10 -- Limit recursion
		AND
		sd.referencing_id != dt.referencing_id 
)
SELECT DISTINCT *
FROM DependencyTree
ORDER BY Level,Path;
