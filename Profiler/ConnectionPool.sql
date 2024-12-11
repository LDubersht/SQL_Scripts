--SELECT TOP 100 * from [dbo].[TexasTraceO2]

DROP TABLE IF EXISTS [dbo].[TexasTraceO2Text]
SELECT EventClass,RowNumber,StartTime,CAST(TextData AS NVARCHAR(MAX)) as TextData  INTO [dbo].[TexasTraceO2Text] from [dbo].[TexasTraceO2]

ALTER TABLE dbo.TexasTraceO2Text ADD CONSTRAINT
	PK_TexasTraceO2Text PRIMARY KEY CLUSTERED 
	(
	RowNumber
	) 


UPDATE [TexasTraceO2Text]
SET TextData = STUFF(
    TextData, 
    PATINDEX('%[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%', TextData),
    32,
    ''
)
WHERE PATINDEX('%[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%', TextData) > 0;


DROP TABLE IF EXISTS [dbo].[TexasTraceO2Groups];

CREATE TABLE [dbo].[TexasTraceO2Groups](
	[StartRowNumber] [int] NOT NULL,
	[EndRowNumber] [int] NOT NULL,
	[GroupID] [bigint] NOT NULL
) 
GO

ALTER TABLE [dbo].[TexasTraceO2Groups] ADD CONSTRAINT
	[PK_TexasTraceO2Groups] PRIMARY KEY CLUSTERED 
	(
		GroupID
	); 


WITH EventMarkers AS (
    SELECT 
        RowNumber,
        EventClass,
        ROW_NUMBER() OVER (ORDER BY RowNumber) AS EventMarkerOrder
    FROM [dbo].[TexasTraceO2Text]
    WHERE EventClass IN (14,15)
)
	INSERT INTO [dbo].[TexasTraceO2Groups]
    SELECT 
        m1.RowNumber+1 AS StartRowNumber,
        m2.RowNumber-1 AS EndRowNumber,
        m1.EventMarkerOrder AS GroupID
    FROM EventMarkers m1
    JOIN EventMarkers m2 ON 
        m2.EventMarkerOrder = m1.EventMarkerOrder + 1 AND
        m2.EventClass = 15 
		AND 
        m1.EventClass = 14
	WHERE m2.RowNumber - m1.RowNumber <30;



DROP TABLE IF EXISTS [dbo].[TexasTraceO2AggregatedTexts];
WITH
AggregatedTexts AS (
    SELECT
        i.GroupID,
        STRING_AGG(t.TextData, Char(13)+char(10)) WITHIN GROUP (ORDER BY t.RowNumber) AS ConsolidatedText
    FROM [dbo].[TexasTraceO2Groups] i
    INNER JOIN [dbo].[TexasTraceO2Text] t ON 
        t.RowNumber BETWEEN i.StartRowNumber AND i.EndRowNumber
    --WHERE t.EventClass NOT IN (14, 15)
    GROUP BY i.GroupID
)
SELECT 
    GroupID,
    ConsolidatedText,
	CAST('' as varbinary(32)) AS HashText
	INTO [dbo].[TexasTraceO2AggregatedTexts]
FROM AggregatedTexts
ORDER BY GroupID;

UPDATE [dbo].[TexasTraceO2AggregatedTexts]
SET HashText = HASHBYTES('MD5',CAST(ConsolidatedText AS NVARCHAR(MAX)))

ALTER TABLE [dbo].[TexasTraceO2AggregatedTexts] ADD CONSTRAINT
	[PK_TexasTraceO2AggregatedTexts] PRIMARY KEY CLUSTERED 
	(
	GroupID
	) 

GO
CREATE NONCLUSTERED INDEX [IX_TexasTraceO2AggregatedTexts_HashText] ON [dbo].[TexasTraceO2AggregatedTexts]
(
	HashText ASC
)
GO


SET NOCOUNT ON;

With Hashes
AS
(
	SELECT count(*) AS Cnt, HashText 
	FROM [dbo].[TexasTraceO2AggregatedTexts] with (nolock)
	GROUP BY HashText
	HAVING count(*) > 10
)
select f.Cnt, a.ConsolidatedText
FROM Hashes f
OUTER APPLY
(select TOP 1 ConsolidatedText 
FROM [dbo].[TexasTraceO2AggregatedTexts] i
WHERE i.HashText = f.HashText) a
ORDER By 1 DESC
