-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 06/11/2024
-- History: 06/11/2024 : Resource 504141 : SOTPT-850
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_WriteOrdersFromCCS]
(
    @CCSData [Orders].[CCSData] READONLY,
    @PipelineRunID NVARCHAR(100),
    @PipelineName NVARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OrderID INT;
    DECLARE @AuditLogID BIGINT;
    DECLARE @HistoryID INT;
    DECLARE @OrderSourceID BIGINT;
	DECLARE @CashCentreTypeCode NVARCHAR(4);

    -- Table variable to capture AuditLogId
    DECLARE @AuditLogIDTable TABLE (AuditLogId BIGINT);
	DECLARE @OrderIDTable TABLE (OrderId BIGINT);

    BEGIN TRY
        -- Insert into DataLoadHistory table and get the AuditLogID
        INSERT INTO [Audit].[DataLoadHistory] (
            [filename],
            [DateTimeReceived],
            [PipelineName],
            [PipelineRunID],
            [Status],
            [ConfirmationNotification],
            [RejectionNotification],
            [ActionTaken],
            [TotalNoOfOrders],
            [TotalNoOfValidOrders],
            [TotalNoOfRejectedOrders],
            [StartTime],
            [EndTime],
            [OrderSourceId]
        )
        OUTPUT Inserted.AuditLogId INTO @AuditLogIDTable(AuditLogId)
        SELECT
            'IVRMigration',                
            GETDATE(),                         
            @PipelineName,                 
            @PipelineRunID,       
            'Imported',                         
            'YES',       
            'NO',           
            'Data loaded successfully',        
            (SELECT COUNT(1) FROM @CCSData),                               
            (SELECT COUNT(1) FROM @CCSData),                               
            0,                                
            GETDATE(),                         -- StartTime
            DATEADD(HOUR, 1, GETDATE()),       -- EndTime
            (SELECT [OrderSourceId] FROM [Reference].[OrderSource] WHERE [OrderSourceCode] = 'IVR');

        -- Retrieve the AuditLogId from the table variable
        SELECT @AuditLogID = AuditLogId FROM @AuditLogIDTable;

        -- Iterate through each row in @CCSData
        DECLARE cur CURSOR FOR
        SELECT ordtype, lcuno, ddate, totval, regStamp, centre, CDR, cashspec, serialno,regOpnos
        FROM @CCSData;

        OPEN cur;

        DECLARE @ordtype CHAR(1), @lcuno CHAR(17), @ddate CHAR(8), @totval DECIMAL(16, 2),@regStamp CHAR(12), @centre CHAR(4), @CDR CHAR(17), @cashspec VARCHAR(MAX),@serialno CHAR(18), @regOpnos CHAR(7);

        FETCH NEXT FROM cur INTO @ordtype, @lcuno, @ddate, @totval,@regStamp, @centre, @CDR, @cashspec, @serialno,@regOpnos;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- Insert into Orders table and get the OrderID
				-- Get CashCentrecode
				IF @ordtype ='N'
				BEGIN
					SET @CashCentreTypeCode = 'NOTE'
				END
				ELSE IF @ordtype LIKE 'C'
				BEGIN
					SET @CashCentreTypeCode = 'COIN'
				END;

				-- Log error into a separate table         


                INSERT INTO [Orders].[Order] (AuditLogId,OrderType,CustomerID,DeliveryDate,OrderValue,OrderDateTime,CarrierRouteCode,CustomerReference,CashCentreID)
                OUTPUT Inserted.OrderId INTO @OrderIDTable(OrderId)
                VALUES (@AuditLogID, 
                         @ordtype,
                        (SELECT [CustomerID] FROM [Customer].[Customer] WHERE [CustomerNumber] = @lcuno),
                        CONVERT(DATE, STUFF(STUFF(@ddate, 5, 0, '-'), 8, 0, '-')),
                        @totval,
                        CONCAT('20', SUBSTRING(@regStamp, 1, 2), '-', 
                         SUBSTRING(@regStamp, 3, 2), '-', 
                         SUBSTRING(@regStamp, 5, 2)),
                        CASE  WHEN @CDR IS NOT NULL THEN LEFT(@CDR, 12)  ELSE @CDR END,
                        @serialno,                       
                        (SELECT CashCentreID from Reference.CashCentre where CashCentreCode=@centre))       

                SELECT @OrderID = OrderId FROM @OrderIDTable;

                -- Split cashspec and insert into OrderDetails table
                -- Step 1: Create a table variable to hold the cashspecc  rows
                DECLARE @SplitTable TABLE (
                    RowValue VARCHAR(MAX)
                );

                -- Step 2: Split the input string into rows based on '#'
                INSERT INTO @SplitTable (RowValue)
                SELECT TRIM(value) FROM STRING_SPLIT(@cashspec, '#')
                WHERE TRIM(value) <> '';

                -- Step 3: Create a cursor to iterate through each row
                DECLARE curSplit CURSOR FOR
                SELECT RowValue FROM @SplitTable;

                OPEN curSplit;

                DECLARE @RowValue VARCHAR(MAX);
                DECLARE @Column1 VARCHAR(50);
                DECLARE @Column2 INT;
                DECLARE @Column3 DECIMAL(10, 2);

                FETCH NEXT FROM curSplit INTO @RowValue;

                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Split each row into columns based on ','
                    SET @Column1 = LEFT(@RowValue, CHARINDEX(',', @RowValue) - 1);
                    SET @RowValue = SUBSTRING(@RowValue, CHARINDEX(',', @RowValue) + 1, LEN(@RowValue));
                    SET @Column2 = CAST(LEFT(@RowValue, CHARINDEX(',', @RowValue) - 1) AS INT);
                    SET @RowValue = SUBSTRING(@RowValue, CHARINDEX(',', @RowValue) + 1, LEN(@RowValue));
                    SET @Column3 = CAST(LEFT(@RowValue, CHARINDEX(',', @RowValue) - 1) AS DECIMAL(10, 2));

                    -- Insert the parsed data into the OrderDetail table
                    INSERT INTO [Orders].[OrderDetail] (OrderID, MediaID, Quantity, Amount)
                    VALUES (
                        @OrderID,
                        (SELECT MediaID FROM Reference.Media WHERE ProductCode = (SELECT ProductCode FROM Reference.CCSIVRMediaMap WHERE CCSITIDCode = @Column1)),
                        @Column2,
                        @Column3
                    );

                    FETCH NEXT FROM curSplit INTO @RowValue;
                END;

                CLOSE curSplit;
                DEALLOCATE curSplit;
                DELETE FROM @SplitTable;
                DELETE FROM @OrderIDTable;
            END TRY
            BEGIN CATCH
               
            END CATCH;

            FETCH NEXT FROM cur INTO @ordtype, @lcuno, @ddate, @totval,@regStamp, @centre, @CDR, @cashspec, @serialno,@regOpnos;
        END;

        CLOSE cur;
        DEALLOCATE cur;
    END TRY
    BEGIN CATCH
        
    END CATCH;
END;
GO
