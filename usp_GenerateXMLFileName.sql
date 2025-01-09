
-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 29/10/2024
-- History: 14/11/2024 : Resource 504141 : SOTPT-767
-- ==================================================================
CREATE PROCEDURE [Output].[usp_GenerateXMLFileName]
                
(
    @IsAmalgamatedCageOrder BIT    
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FileNamePrefix VARCHAR(20);
    DECLARE @DateTimeStamp VARCHAR(20);
    DECLARE @TodaysDate DATE;
    DECLARE @NextSequenceNumber INT;
    DECLARE @NexttSequenceNumberAsString VARCHAR(3);
    DECLARE @XMLFileName VARCHAR(100);
    DECLARE @LastSequenceNumber INT;
    DECLARE @LastFilename VARCHAR(100);
    DECLARE @CurrentLondonTime DATETIMEOFFSET;
    DECLARE @LastFileDate DATE;
    DECLARE @ExtractedDate VARCHAR(10);
    DECLARE @FileName NVARCHAR(100);

    -- Get current time in London (automatically adjusts for BST/GMT)
    SET @CurrentLondonTime = SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time';
    SET @TodaysDate = CAST(@CurrentLondonTime AS DATE);
    SET @FileNamePrefix = CASE WHEN @IsAmalgamatedCageOrder = 1 THEN 'isa-order-amalg-' ELSE 'isa-order-' END;
    SET @DateTimeStamp = FORMAT(@CurrentLondonTime, 'yyyy-MM-dd-HHmmss');  
	
	

    BEGIN TRY
        BEGIN TRANSACTION; -- Start the transaction

        IF @IsAmalgamatedCageOrder = 1
        BEGIN
            SET @LastFilename = (SELECT TOP (1) FileName 
                                  FROM [Output].[FileOut] fo								 
                                  WHERE FileName  LIKE '%isa-order-amalg%' 								
                                  ORDER BY FileName DESC);
        END
        ELSE
        BEGIN
            SET @LastFilename = (SELECT TOP (1) FileName 
                                  FROM [Output].[FileOut] fo								 
                                  WHERE filename LIKE 'isa-order-%'
					              AND filename NOT LIKE 'isa-order-amalg%'
					              ORDER BY filename DESC);
        END

      

        IF @LastFilename IS NOT NULL
        BEGIN           
            IF @LastFilename LIKE '%amalg%'
            BEGIN
                SET @ExtractedDate = SUBSTRING(@LastFilename, 17, 10);
            END
            ELSE 
            BEGIN
                SET @ExtractedDate = SUBSTRING(@LastFilename, 11, 10);
            END; 
            
            -- Ensure the extracted date is in the correct format
            IF ISDATE(@ExtractedDate) = 1
            BEGIN
                SET @LastFileDate = CAST(@ExtractedDate AS DATE);
            END
            ELSE
            BEGIN
                ROLLBACK TRANSACTION;
                RETURN;
            END

            IF @LastFileDate < @TodaysDate
            BEGIN
                SET @NexttSequenceNumberAsString = '001';
            END
            ELSE
            BEGIN
                IF @LastFilename LIKE '%amalg%'
                BEGIN    
                    SET @LastSequenceNumber = CAST(SUBSTRING(@LastFilename, 49, 3) AS INT);
                END
                ELSE 
                BEGIN
                    SET @LastSequenceNumber = CAST(SUBSTRING(@LastFilename, 29, 3) AS INT);
                END; 

                SET @NextSequenceNumber = @LastSequenceNumber + 1;
                SET @NexttSequenceNumberAsString = RIGHT('000' + CAST(@NextSequenceNumber AS VARCHAR(3)), 3);
            END    
        END
        ELSE
        BEGIN
            SET @NexttSequenceNumberAsString = '001';
        END

        SET @XMLFileName = CASE 
            WHEN @IsAmalgamatedCageOrder = 1 THEN
                CONCAT(@FileNamePrefix, @DateTimeStamp, '_{RouteClient}_', @NexttSequenceNumberAsString, '.xml')
            ELSE
                CONCAT(@FileNamePrefix, @DateTimeStamp, '_', @NexttSequenceNumberAsString, '.xml')
        END;

        -- Write the file name into this data for this order file 
        
        INSERT INTO [Output].[FileOut] (FileName, IsAmalgamatedCageOrder)
        values(@XMLFileName, @IsAmalgamatedCageOrder)

        COMMIT TRANSACTION; -- Commit the transaction
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION; -- Rollback the transaction if an error occurs
			
        END
        RETURN;
    END CATCH

    SELECT @XMLFileName AS XMLFileName;
END;
GO