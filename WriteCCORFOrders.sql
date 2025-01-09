-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 08/08/2024
-- Description: ImPort orders into DB.
-- History: 13/08/2024 : Resource 503436 : SOTPT-264
-- History: 10/10/2024 : Resource 503436 : SOTPT-652
-- History: 11/10/2024 : Resource 503436 : SOTPT-726
-- History: 17/10/2024 : Resource 503436 : SOTPT-776
-- History: 18/10/2024 : Resource 503436 : SOTPT-726
-- History: 11/11/2024 : Resource 504141 : SOTPT-896

-- ==================================================================
CREATE PROCEDURE [CCORF].[WriteCCORFOrders]
(
    @FileName VARCHAR(100),
	@DateTimeReceived DATETIME2,
	@FileRejected BIT,
	@OrganisationIdentifier VARCHAR(17),
	@Orders [CCORF].[OrderList] READONLY,
	@Details [CCORF].[OrderDetailList] READONLY,
	@CommaSeparatedHeaderErrors VARCHAR(100) NULL, -- 20 errors max or NULL for no errors.
	@CommaSeparatedTrailerErrors VARCHAR(100) NULL -- 20 errors max or NULL for no errors.
)
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION [Tran1]

		DECLARE @TempAuditIds TABLE (AuditId BIGINT)
		DECLARE @NumValidOrders INT
		DECLARE @NumInvalidOrders INT
		DECLARE @AuditPK BIGINT
		DECLARE @TempOrderIds TABLE (OrderId BIGINT)
		DECLARE @OrderPK BIGINT
		DECLARE @TempDetailIds TABLE (DetailId BIGINT)
		DECLARE @DetailPK BIGINT
		DECLARE @Errors TABLE(Ec VARCHAR(4))
		DECLARE @Lcuno VARCHAR(17)

		SELECT @NumValidOrders=COUNT(*) FROM @Orders WHERE InvalidOrder = 0
		SELECT @NumInvalidOrders=COUNT(*) FROM @Orders WHERE InvalidOrder = 1

		INSERT INTO [Audit].[DataLoadHistory]
			([filename]
			,[DateTimeReceived]
			,[PipelineName] -- todo: What is this?
			,[PipelineRunID] -- todo: What is this?
			,[Status] -- todo: What is this?
			,[ConfirmationNotification] -- todo: What is this?
			,[RejectionNotification] -- todo: What is this?
			,[ActionTaken] -- todo: What is this?
			,[TotalNoOfOrders]
			,[TotalNoOfValidOrders]
			,[TotalNoOfRejectedOrders]
			,[StartTime] -- todo: Start time of what?
			,[EndTime] -- todo: End time of what?
			,[OrderSourceId]
			,[IsActive])
		OUTPUT Inserted.AuditLogId INTO @TempAuditIds
		VALUES
			(@FileName
			,@DateTimeReceived
			,''-- todo: What is this?
			,''-- todo: What is this?
			,CASE WHEN @FileRejected = 1 THEN 'FileRejected' ELSE 'FileImported' END
			,'??' -- todo: What is this?
			,'??' -- todo: What is this?
			,'??' -- todo: What is this?
			,@NumValidOrders + @NumInvalidOrders
			,@NumValidOrders
			,@NumInvalidOrders
			,'1800-01-01 00:00:00' -- todo: Start time of what?
			,'1800-01-01 00:00:00' -- todo: End time of what?
			,(SELECT [OrderSourceId] FROM [Reference].[OrderSource] WHERE [OrderSourceCode] = 'BRCCORF')
			,1
			)

		SELECT @AuditPK = AuditId FROM @TempAuditIds;

		-- Insert header errors.
		IF @CommaSeparatedHeaderErrors IS NOT NULL BEGIN
			INSERT INTO @Errors
			SELECT * FROM STRING_SPLIT(@CommaSeparatedHeaderErrors, ',')

			INSERT INTO [Error].[Error] ([ErrorCodeId], [FileError])
			SELECT [ErrorCodeId], @AuditPK as [FileError] from @Errors
			LEFT JOIN Reference.ErrorCode on ErrorCode = Ec
		END

		-- Insert trailer errors.
		IF @CommaSeparatedTrailerErrors IS NOT NULL BEGIN
			DELETE FROM @Errors
			INSERT INTO @Errors
			SELECT * FROM STRING_SPLIT(@CommaSeparatedTrailerErrors, ',')

			INSERT INTO [Error].[Error] ([ErrorCodeId], [FileError])
			SELECT [ErrorCodeId], @AuditPK as [FileError] from @Errors
			LEFT JOIN Reference.ErrorCode on ErrorCode = Ec
		END

		DECLARE
			@OrderRowNo INT,
			@OrderLocationID VARCHAR(17),
			@OrderOrderDate DATE,
			@OrderRawOrderData VARCHAR(150),
			@OrderDeliveryDate DATE,
			@OrderTotalValue VARCHAR(19),
			@OrderCarrierRouteCode VARCHAR(12),
			@OrderCustomerReference VARCHAR(10),
			@OrderOrderType CHAR(1),
			@OrderInvalidOrder BIT,
			@OrderCommaSeparatedErrorCodes VARCHAR(100)

		DECLARE OrderCursor CURSOR FOR SELECT RowNo, LocationID, OrderDate, RawOrderData, DeliveryDate, TotalValue, CarrierRouteCode, CustomerReference, OrderType, InvalidOrder, CommaSeparatedErrorCodes FROM @Orders

		OPEN OrderCursor
		FETCH NEXT FROM OrderCursor INTO @OrderRowNo, @OrderLocationID, @OrderOrderDate, @OrderRawOrderData, @OrderDeliveryDate, @OrderTotalValue, @OrderCarrierRouteCode, @OrderCustomerReference, @OrderOrderType, @OrderInvalidOrder, @OrderCommaSeparatedErrorCodes
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @Lcuno = [CustomerNumber] FROM [Customer].[Organisation]
			INNER JOIN [Customer].[CustomerResiliencyMap] ON [Organisation].[OrganisationID] = [CustomerResiliencyMap].[OrganisationID]
			WHERE RIGHT(REPLICATE('0', 17) + [OrganisationIdentifier], 17) = @OrganisationIdentifier AND [CustomerLocationID]=@OrderLocationID
				AND [Organisation].[IsActive] = 1 AND [CustomerResiliencyMap].[IsActive] = 1
			IF (@OrderInvalidOrder = 0) BEGIN
				INSERT INTO [Orders].[Order]
					([AuditLogId]
					,[OrderType]
					,[LocationID]
					,[CustomerID]
					,[DeliveryDate]
					,[OrderValue]
					,[OrderDateTime]
					,[RawOrderData]
					,[CarrierRouteCode]
					,[CustomerReference]
					,[CashCentreID])
				OUTPUT Inserted.OrderId INTO @TempOrderIds
				VALUES
					(@AuditPK,
					@OrderOrderType,
					(SELECT [CustomerResiliencyMapID] FROM [Customer].[CustomerResiliencyMap]
						INNER JOIN [Customer].[Organisation] ON [Organisation].[OrganisationID] = [CustomerResiliencyMap].[OrganisationID]
						WHERE [Organisation].[IsActive] = 1 AND [CustomerResiliencyMap].[IsActive] = 1 AND RIGHT(REPLICATE('0', 17) + [Organisation].[OrganisationIdentifier], 17) = @OrganisationIdentifier
						AND [CustomerResiliencyMap].[CustomerLocationID] = @OrderLocationID),
					(SELECT [CustomerID] FROM [Customer].[Customer] WHERE [CustomerNumber] = @Lcuno),
					@OrderDeliveryDate,
					@OrderTotalValue,
					@OrderOrderDate,
					@OrderRawOrderData,
					@OrderCarrierRouteCode,
					@OrderCustomerReference,					
				(SELECT [CashCentreID] FROM [Customer].[Customer]
							INNER JOIN [Customer].[ProductServiceCustomer] ON [ProductServiceCustomer].[CustomerID] = [Customer].[CustomerID]
							INNER JOIN [Reference].[CashCentre] ON [CashCentre].[CashCentreCode] = [ProductServiceCustomer].[CashCentreCode]
							INNER JOIN [Reference].[ProductService] ON [ProductService].[ProductServiceID]=[ProductServiceCustomer].[ProductServiceID]
							INNER JOIN [Reference].[Product] ON [Product].[ProductID] =[ProductService].[ProductID]
							INNER JOIN [Reference].[Service] ON [Service].[ServiceID]=[ProductService].[ServiceID]
							AND [Product].ProductCode='OUT' AND [Service].[ServiceCode]='CO'
							WHERE [CustomerNumber] = @Lcuno AND [CashCentreTypeCode] = IIF(@OrderOrderType = 'C', 'COIN', 'NOTE') AND [CashCentre].[IsActive] = 1))

				SELECT @OrderPK = OrderId FROM @TempOrderIds;

				-- Insert details
				INSERT INTO [Orders].[OrderDetail]
					([OrderId],
					[MediaID],
					[Quantity],
					[Amount],
				    [RawOrderData])
				SELECT @OrderPK, [MediaID], [Quantity], [Amount], [RawOrderData] FROM @Details
				LEFT JOIN [Reference].[Media] ON [Media].[ProductCode] = CONCAT([@Details].[ProductCode], [@Details].[ProductItemDetails])
				WHERE OrderRowNo = @OrderRowNo
			END ELSE BEGIN
				-- Invalid order.
				INSERT INTO [Orders].[OrderFailed]
					([AuditLogId]
					,[OrderType]
					,[OrganisationIdentifier]
					,[LocationID]
					,[CustomerNumber]
					,[DeliveryDate]
					,[OrderValue]
					,[OrderDateTime]
					,[RawOrderData]
					,[CarrierRouteCode]
					,[CustomerReference])
				OUTPUT Inserted.OrderFailedId INTO @TempOrderIds
				VALUES
					(@AuditPK,
					@OrderOrderType,
					@OrganisationIdentifier,
					@OrderLocationID,
					ISNULL(@Lcuno, ''), -- Empty string due to column being NOT NULL.
					@OrderDeliveryDate,
					@OrderTotalValue,
					@OrderOrderDate,
					@OrderRawOrderData,
					@OrderCarrierRouteCode,
					@OrderCustomerReference)

				SELECT @OrderPK = OrderId FROM @TempOrderIds;

				-- Order errors.
				DELETE FROM @Errors
				INSERT INTO @Errors
				SELECT * FROM STRING_SPLIT(@OrderCommaSeparatedErrorCodes, ',')

				INSERT INTO [Error].[Error] (ErrorCodeId, OrderFailedId)
				SELECT [ErrorCodeId], @OrderPK as OrderId from @Errors
				LEFT JOIN Reference.ErrorCode on ErrorCode = Ec

				-- Insert details
				DECLARE @DetailProductCode VARCHAR(50),
					@DetailQuantity BIGINT,
					@DetailAmount VARCHAR(19),
					@DetailProductItemDetails CHAR(3),
					@DetailRawData VARCHAR(150),
					@DetailCommaSeparatedErrorCodes VARCHAR(100)
				DECLARE DetailCursor CURSOR FOR SELECT ProductCode, Quantity, Amount, ProductItemDetails, RawOrderData, CommaSeparatedErrorCodes FROM @Details WHERE OrderRowNo = @OrderRowNo

				OPEN DetailCursor
				FETCH NEXT FROM DetailCursor INTO @DetailProductCode, @DetailQuantity, @DetailAmount, @DetailProductItemDetails, @DetailRawData, @DetailCommaSeparatedErrorCodes
				WHILE @@FETCH_STATUS = 0
				BEGIN
					INSERT INTO [Orders].[OrderDetailFailed]
						([OrderFailedId],
						[ProductCode],
						[Quantity],
						[Amount],
						[ProductItemDetails],
						[RawOrderData])
					OUTPUT Inserted.OrderDetailFailedID INTO @TempDetailIds
					VALUES
						(@OrderPK, @DetailProductCode, @DetailQuantity, @DetailAmount, @DetailProductItemDetails, @DetailRawData)

					SELECT @DetailPK = DetailId FROM @TempDetailIds


					-- Insert detail errors.
					DELETE FROM @Errors
					INSERT INTO @Errors
					SELECT * FROM STRING_SPLIT(@DetailCommaSeparatedErrorCodes, ',')

					INSERT INTO [Error].[Error] (ErrorCodeId, OrderDetailFailedId)
					SELECT [ErrorCodeId], @DetailPK as OrderId from @Errors
					LEFT JOIN Reference.ErrorCode on ErrorCode = Ec

					FETCH NEXT FROM DetailCursor INTO @DetailProductCode, @DetailQuantity, @DetailAmount, @DetailProductItemDetails, @DetailRawData, @DetailCommaSeparatedErrorCodes
				END
				CLOSE DetailCursor
				DEALLOCATE DetailCursor
			END

			FETCH NEXT FROM OrderCursor INTO @OrderRowNo, @OrderLocationID, @OrderOrderDate, @OrderRawOrderData, @OrderDeliveryDate, @OrderTotalValue, @OrderCarrierRouteCode, @OrderCustomerReference, @OrderOrderType, @OrderInvalidOrder, @OrderCommaSeparatedErrorCodes
		END

		CLOSE OrderCursor
		DEALLOCATE OrderCursor

		COMMIT TRANSACTION [Tran1]
		SELECT @AuditPK
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION [Tran1];
		THROW
	END CATCH

END
GO

