DECLARE @FileName NVARCHAR(128),
		@FileType int,
        @FileSizeMB FLOAT,
		@DestFileSizeMB int,
        @AvailableSpaceMB FLOAT,
        @ShrinkDataStepSizeMB INT = 500,
        @ShrinkLogStepSizeMB INT = 1500,
        @WaitTimeAfterStep INT = 10, -- in seconds
        @WaitTimeAfterCycle INT = 60, -- in seconds
		@DataFileThreshold INT = 5, --for start shrink in persent
		@LogFileThreshold INT = 15, --for start shrink in persent
		@StartTime DATETIME,
		@ElapsedTime INT;

WHILE 1 = 1
BEGIN
    -- Определяем размеры файлов и доступное пространство
    DECLARE FileCursor CURSOR FOR
    SELECT name, 
			type,
           size / 128.0 AS FileSizeMB,
           size / 128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0 AS AvailableSpaceMB
    FROM sys.database_files;

    OPEN FileCursor;
    FETCH NEXT FROM FileCursor INTO @FileName, @FileType, @FileSizeMB, @AvailableSpaceMB;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (@AvailableSpaceMB / @FileSizeMB) * 100 > @DataFileThreshold and @FileType = 0
        BEGIN
            SET @StartTime = GETDATE();
			SET @DestFileSizeMB = CAST(@FileSizeMB - @ShrinkDataStepSizeMB AS INT)
			IF @FileSizeMB>@DestFileSizeMB
				DBCC SHRINKFILE (@FileName, @DestFileSizeMB);

            SET @ElapsedTime = DATEDIFF(SECOND, @StartTime, GETDATE());
            RAISERROR ('Shrink step completed for file %s. Time taken: %d seconds.', 10, 1, @FileName, @ElapsedTime) WITH NOWAIT;

            WAITFOR DELAY '00:00:10';
        END
		ELSE IF (@AvailableSpaceMB / @FileSizeMB) * 100 > @LogFileThreshold and @FileType = 1
		BEGIN
            SET @StartTime = GETDATE();
			SET @DestFileSizeMB = CAST(@FileSizeMB-@ShrinkLogStepSizeMB AS INT)
			IF @FileSizeMB>@DestFileSizeMB
				DBCC SHRINKFILE (@FileName, @DestFileSizeMB);

            SET @ElapsedTime = DATEDIFF(SECOND, @StartTime, GETDATE());
            RAISERROR ('Shrink step completed for file %s. Time taken: %d seconds.', 10, 1, @FileName, @ElapsedTime) WITH NOWAIT;

            WAITFOR DELAY '00:00:10';
        END
        ELSE
        BEGIN
            RAISERROR ('File %s has less than 5%% free space. Waiting for the next cycle.', 10, 1, @FileName) WITH NOWAIT;
            WAITFOR DELAY '00:01:00';
        END

        FETCH NEXT FROM FileCursor INTO @FileName, @FileType, @FileSizeMB, @AvailableSpaceMB;
    END

    CLOSE FileCursor;
    DEALLOCATE FileCursor;
END
