
-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 29/10/2024
-- History: 15/11/2024 : Resource 504141 : SOTPT-767
-- History: 20/11/2024 : Resource 504141 : SOTPT-765
-- History: 20/11/2024 : Resource 504141 : SOTPT-915 --updated to support ivr both coin and note
-- ==================================================================
CREATE PROCEDURE [Output].[usp_GenerateXMLFile]
(
    @AuditLogID INT,
	@FileName NVARCHAR(100),
    @RouteClient VARCHAR(10) = ''	
)
AS
BEGIN

BEGIN TRY
	SET NOCOUNT ON;

	DECLARE @OrderXML XML;
	DECLARE @innerXML XML;
	DECLARE @TransformStatus VARCHAR(10) = 'Prepared'

	DECLARE @ProductCodeTable TABLE
	(
		[OrderID] BIGINT NOT NULL,
		[ProductCode] VARCHAR(50) NOT NULL,		
		[Amount] VARCHAR(50) NOT NULL,
		[Count] VARCHAR(50) NOT NULL
	)
	DECLARE @OrderStagingTable TABLE
	(
			[OrderId] [bigint]  NOT NULL,
			[AuditLogId] [bigint] NOT NULL,
			[OrderType] [varchar](1) NOT NULL,
			[CustomerNumber] [varchar](17) NOT NULL,
			[DeliveryDate] DATE NOT NULL,
			[OrderValue] [decimal](16, 2) NOT NULL,
			[OrderDateTime] [varchar](16) NOT NULL,
			[CarrierRouteCode] [varchar](12)  NULL,
			[CustomerReference] [varchar](18)  NULL,
			[TransformedStatus] [varchar](18) NULL,
			[CashCentreDescription] [varchar](100) NOT NULL,
		    [CashCentreCode] [varchar](50) NOT NULL,
			[RouteClient] [varchar](10) NULL,
			[ClientCode] [varchar](63) NULL
	)


	INSERT INTO @OrderStagingTable
		SELECT   [OrderId] ,
				[AuditLogId] ,
				[OrderType] ,
				C.CustomerNumber ,
				[DeliveryDate] ,
				[OrderValue] ,
				[OrderDateTime] ,
				[CarrierRouteCode] ,
				[CustomerReference] ,
				[TransformedStatus],
	(SELECT CONCAT([CashCentre].[CashCentreDescription],' - ', UPPER(LEFT([CashCentre].CashCentreTypeCode, 1)), 
	        LOWER(SUBSTRING([CashCentre].CashCentreTypeCode, 2, LEN([CashCentre].CashCentreTypeCode)))) AS CashCentreTypeCode
			FROM [Reference].[CashCentre]
			where [CashCentreTypeCode] = IIF(o.OrderType = 'C', 'COIN', 'NOTE') and CashCentreCode=(select CashCentreCode from Reference.CashCentre where CashCentreID=o.CashCentreID AND [CashCentre].[IsActive] = 1)),
	(SELECT CashCentreCode from [Reference].CashCentre where CashCentreID=o.CashCentreID AND [CashCentre].[IsActive] = 1),
	(SELECT  CONCAT('DD', CashProcessingOptionValue, CashCentreCode) 
			FROM    [Customer].[CashProcessingOption] CPO
			INNER JOIN   [Customer].[Customer] c ON c.CustomerID = CPO.CustomerID
			INNER JOIN   Reference.CashProcessingRule CR ON CR.CashProcessingRuleID = CPO.CashProcessingRuleID
			INNER JOIN   Customer.ProductServiceCustomer psc ON psc.CustomerID = c.CustomerID
			AND psc.ProductServiceID = CPO.ProductServiceID
			WHERE c.CustomerID = o.CustomerID AND cr.CashProcessingRuleCode = 'CAP0013' and CashCentreCode=(select CashCentreCode from Reference.CashCentre where CashCentreID=o.CashCentreID AND [CashCentre].[IsActive] = 1)),
	(SELECT  psc.ISAClientCode  FROM   [Customer].[ProductServiceCustomer] psc
			INNER JOIN [Customer].[Customer] c ON psc.CustomerID = c.CustomerID
			INNER JOIN [Customer].[CashProcessingOption] CPO ON psc.CustomerID = CPO.CustomerID  AND psc.ProductServiceID = CPO.ProductServiceID
			INNER JOIN Reference.CashProcessingRule CR ON CR.CashProcessingRuleID = CPO.CashProcessingRuleID
			INNER JOIN Reference.CashCentre Cc on cc.CashCentreCode=psc.CashCentreCode
			WHERE c.CustomerID = o.CustomerID  AND cr.CashProcessingRuleCode = 'CAP0013'  and [CashCentreTypeCode] = IIF(o.OrderType = 'C', 'COIN', 'NOTE') and CC.CashCentreCode=(select CashCentreCode from Reference.CashCentre where CashCentreID=o.CashCentreID AND [CashCentre].[IsActive] = 1))
	FROM [Orders].[Order] o	
	INNER JOIN Customer.Customer C
	ON o.CustomerID=C.CustomerID
    AND o.TransformedStatus=@TransformStatus
    AND o.AuditLogId= @AuditLogID

IF COALESCE(@RouteClient, '') = ''		--Standard Orders
BEGIN	
		INSERT INTO @ProductCodeTable		
			SELECT 
				od.[OrderID],
				ProductCode,
				Amount,
				Quantity
			FROM 
				[Orders].[OrderDetail] od
				INNER JOIN [Reference].[Media] ON [Media].[MediaID] = od.[MediaID]
                INNER JOIN @OrderStagingTable o ON od.OrderID = o.OrderID
			WHERE
				o.AuditLogId = @AuditLogID

		SET @innerXML = (
			--Get XML
			SELECT
				CashCentreDescription AS [@Name],
				(SELECT
					ClientCode AS [@ClientCode],
					Convert(VARCHAR, Convert(DATETIME, [DeliveryDate], 23), 23) AS [@DeliveryDate],
					[OrderValue] AS [@OrderValue],
					CustomerReference AS [@ClientReference],
					--OrderType AS [@OrderNotes],
					CustomerReference AS [@OrderId1],
					--[HistDate] AS [@OrderId2],
					 CONCAT(CarrierRouteCode,CashCentreCode) AS [@Branch],
					 [RouteClient] AS [@Route],
					(SELECT
						pct.[Count] AS [@Quantity],
						pct.[ProductCode] AS [@ProductCode]
					FROM @ProductCodeTable pct
					WHERE
						T2.OrderID = pct.OrderID
					FOR XML PATH('Media'), TYPE)
				FROM @OrderStagingTable T2
				WHERE T2.CashCentreDescription = T.CashCentreDescription AND T2.[TransformedStatus] = @TransformStatus AND T2.AuditLogId = @AuditLogID
				FOR XML PATH('Order'), TYPE)
			FROM @OrderStagingTable T 
			WHERE T.AuditLogId = @AuditLogID
			GROUP BY
				CashCentreDescription
			FOR XML PATH('EntryCashCentre'),ROOT('ISAOrderImport') , ELEMENTS XSINIL 
		)
		SET @OrderXML = (
						SELECT 1 AS Tag
								,NULL AS Parent
								,@innerXML AS [ISAOrderImport!1!!xmltext]
								,'ISAOrderImport.xsd' AS [ISAOrderImport!1!xsi:noNamespaceSchemaLocation]
						FOR XML EXPLICIT 
						)

		UPDATE [Orders].[Order]
		SET
			[TransformedStatus] = 'Sent',
			FileOutID = (select FileOutID from [Output].[FileOut] where FileName=@FileName)
		WHERE
			AuditLogId = @AuditLogID
			AND
			[TransformedStatus] <> 'Error'
	END
	ELSE											--Amalgamated Orders
	BEGIN
		INSERT INTO @ProductCodeTable
		SELECT 
				od.[OrderID],
				LEFT(ProductCode,LEN(ProductCode) - 3) AS ProductCode,
				Amount,
				Quantity
			FROM 
				[Orders].[OrderDetail] od
				INNER JOIN [Reference].[Media] ON [Media].[MediaID] = od.[MediaID]
                INNER JOIN @OrderStagingTable o ON od.OrderID = o.OrderID
			WHERE
				o.AuditLogId = @AuditLogID
				AND
				[RouteClient] = @RouteClient

		SET @innerXML = (
			--Get XML
			SELECT
				CashCentreDescription AS [@Name],
				(
					SELECT
						ClientCode AS [@ClientCode],
						Convert(VARCHAR, Convert(DATETIME, [DeliveryDate], 23), 23) AS [@DeliveryDate],
						[OrderValue] AS [@OrderValue],
						CustomerReference AS [@ClientReference],
						--OrderType AS [@OrderNotes],
						CustomerReference AS [@OrderId1],
						--[HistDate] AS [@OrderId2],
						CONCAT(CarrierRouteCode,CashCentreCode) AS [@Branch],
						[RouteClient] AS [@Route],
						(
							SELECT
								pct.[Count] AS [@Quantity],
								pct.[ProductCode] AS [@ProductCode]
							FROM @ProductCodeTable pct
							WHERE
								T2.OrderID = pct.OrderID
							FOR XML PATH('Media'), TYPE
						)
					FROM @OrderStagingTable T2
					WHERE T2.CashCentreDescription = T.CashCentreDescription AND T2.[TransformedStatus] = @TransformStatus AND T2.AuditLogId = @AuditLogID 
					AND T2.RouteClient = @RouteClient
					FOR XML PATH('Order'), TYPE
				)
			FROM @OrderStagingTable T 
			WHERE T.AuditLogId = @AuditLogID 
			--AND T.RouteClient = @RouteClient
			GROUP BY
				CashCentreDescription
			FOR XML PATH('EntryCashCentre'),ROOT('ISAOrderImport') , ELEMENTS XSINIL 
		)

		SET @OrderXML = (
						SELECT 1 AS Tag
								,NULL AS Parent
								,@innerXML AS [ISAOrderImport!1!!xmltext]
								,'ISAOrderImport.xsd' AS [ISAOrderImport!1!xsi:noNamespaceSchemaLocation]
						FOR XML EXPLICIT 
						)

		UPDATE [Orders].[Order]
		SET
			[TransformedStatus] = 'Sent',
			 FileOutID = (select FileOutID from [Output].[FileOut] where FileName=@FileName)
		WHERE
			AuditLogId = @AuditLogID
			AND
			--RouteClient = @RouteClient
			--AND
			[TransformedStatus] <> 'Error'
	
	END

	DECLARE @xmlProlog AS VARCHAR(100) = '<?xml version="1.0" encoding="utf-8"?>'
	--Can't add the default encoding XML prolog to XML data type, as internally in SQL Server, it is UTF-16
	DECLARE @OrderXMLAsString AS NVARCHAR(MAX)

	SET @OrderXMLAsString = @xmlProlog + CAST(@OrderXML AS NVARCHAR(MAX))

	SELECT @OrderXMLAsString

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION; -- Rollback the transaction if an error occurs
	
END
RETURN;
END CATCH

END;
GO
