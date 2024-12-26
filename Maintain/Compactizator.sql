DECLARE @FileName NVARCHAR(128),
		@FileType int,
        @FileSizeMB FLOAT,
		@DestFileSizeMB int,
        @AvailableSpaceMB FLOAT,
        @ShrinkDataStepSizeMB INT = 500,
        @ShrinkLogStepSizePercent INT = 10,
        @WaitTimeAfterStep INT = 10, -- in seconds
        @WaitTimeAfterCycle INT = 60, -- in seconds
		@DataFileThreshold INT = 5, --for start shrink in persent
		@LogFileThreshold INT = 15, --for start shrink in persent
		@FileSizeLimitMB INT = 10000, -- min file size 
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
        IF @FileType = 0 
		BEGIN
			SET @DestFileSizeMB = CAST(@FileSizeMB - @ShrinkDataStepSizeMB AS INT)
			IF (@AvailableSpaceMB / @FileSizeMB) * 100 > @DataFileThreshold 
				AND  @DestFileSizeMB > @FileSizeLimitMB
				AND  @FileSizeMB > @DestFileSizeMB
			BEGIN
				SET @StartTime = GETDATE();
				
				DBCC SHRINKFILE (@FileName, @DestFileSizeMB);

				SET @ElapsedTime = DATEDIFF(SECOND, @StartTime, GETDATE());
				RAISERROR ('Shrink step completed for file %s. Time taken: %d seconds.', 10, 1, @FileName, @ElapsedTime) WITH NOWAIT;

				WAITFOR DELAY '00:00:01';
			END
			ELSE 
		    BEGIN
				RAISERROR ('DataFile %s has less than free space. Waiting for the next cycle.', 10, 1, @FileName) WITH NOWAIT;
				WAITFOR DELAY '00:01:01';
			END
		END
		IF  @FileType = 1
		BEGIN
			SET @DestFileSizeMB = CAST(@FileSizeMB*(100-@ShrinkLogStepSizePercent)/100 AS INT)
			IF (@AvailableSpaceMB / @FileSizeMB) * 100 > @LogFileThreshold 
				AND @FileSizeMB>@DestFileSizeMB AND @DestFileSizeMB > @FileSizeLimitMB
			BEGIN
				SET @StartTime = GETDATE();
				
				DBCC SHRINKFILE (@FileName, @DestFileSizeMB);

				SET @ElapsedTime = DATEDIFF(SECOND, @StartTime, GETDATE());
				RAISERROR ('Shrink step completed for file %s. Time taken: %d seconds.', 10, 1, @FileName, @ElapsedTime) WITH NOWAIT;

				WAITFOR DELAY '00:00:01';
			END
			ELSE
			BEGIN
				RAISERROR ('File %s has less than free space. Waiting for the next cycle.', 10, 1, @FileName) WITH NOWAIT;
				WAITFOR DELAY '00:01:01';
			END
		END
        
		FETCH NEXT FROM FileCursor INTO @FileName, @FileType, @FileSizeMB, @AvailableSpaceMB;
    END

    CLOSE FileCursor;
    DEALLOCATE FileCursor;
END
