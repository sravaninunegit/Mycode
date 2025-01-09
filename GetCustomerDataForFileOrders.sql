-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 29/10/2024
-- Description: Get cash-out customer data for function app.
-- History: 07/11/2024 : Resource 503436 : SOTPT-838
-- History: 20/11/2024 : Resource 503436 : SOTPT-840
-- ==================================================================
CREATE PROCEDURE [Customer].[GetCustomerDataForFileOrders] (
	@CustomerNumbers [Customer].[CustomerNumberList] READONLY
)
AS BEGIN
	DECLARE @CAP0013 BIGINT;

	SELECT @CAP0013 = [CashProcessingRuleID] FROM [Reference].[CashProcessingRule] WHERE [CashProcessingRuleCode] = 'CAP0013'

	SELECT [CustomerNumber], [CustomerStatusCode] FROM [Customer].[Customer]
	INNER JOIN [Reference].[CustomerStatus] ON [CustomerStatus].[CustomerStatusID] = [Customer].[CustomerStatusID]
	WHERE [Customer].[IsActive] = 1 AND [Customer].[CustomerNumber] IN (SELECT [CustomerNumber] FROM @CustomerNumbers)

	SELECT [CustomerNumber], [ServiceCode], [ServiceTypeCode], [ProductCode], [CashCentre].[CashCentreCode], [CashCentre].[IsActive] AS 'CashCentreActive', [CashProcessingOptionValue] 'DeliveryLead' FROM [Customer].[Customer]
	INNER JOIN [Customer].[ProductServiceCustomer] ON [ProductServiceCustomer].[CustomerID] = [Customer].[CustomerID]
	INNER JOIN [Reference].[ProductService] ON [ProductService].[ProductServiceID] = [ProductServiceCustomer].[ProductServiceID]
	INNER JOIN [Reference].[Service] ON [ProductService].[ServiceID] = [Service].[ServiceID]
	INNER JOIN [Reference].[ServiceType] ON [ServiceType].[ServiceTypeID] = [Service].[ServiceTypeID]
	INNER JOIN [Reference].[Product] ON [Product].[ProductID] = [ProductService].[ProductID]
	LEFT JOIN [Reference].[CashCentre] ON [ProductServiceCustomer].[CashCentreCode] = [CashCentre].[CashCentreCode]
	LEFT JOIN [Customer].[CashProcessingOption] ON [CashProcessingOption].[CustomerID] = [Customer].[CustomerID] AND [CashProcessingOption].[ProductServiceID] =  [ProductServiceCustomer].[ProductServiceID] AND [CashProcessingRuleID] = @CAP0013
	WHERE [Customer].[CustomerNumber] IN (SELECT [CustomerNumber] FROM @CustomerNumbers)
	AND [ServiceCode]='CO' AND [Product].[ProductCode]='OUT'
	ORDER BY [CustomerNumber]

	SELECT [CustomerNumber], [ServiceCode], [ServiceTypeCode], [ProductCode], [DayOfWeekCode], [CarrierRouteCode] FROM [Customer].[ProductServiceCustomerCarrier]
	INNER JOIN [Customer].[ProductServiceCustomer] ON [ProductServiceCustomer].[ProductServiceCustomerID] = [ProductServiceCustomerCarrier].[ProductServiceCustomerID]
	INNER JOIN [Customer].[Customer] ON [Customer].[CustomerID] = [ProductServiceCustomer].[CustomerID]
	INNER JOIN [Reference].[DayOfWeek] ON [DayOfWeek].[DayOfWeekID] = [ProductServiceCustomerCarrier].[DayOfWeekID]
	INNER JOIN [Reference].[ProductService] ON [ProductService].[ProductServiceID] = [ProductServiceCustomer].[ProductServiceID]
	INNER JOIN [Reference].[Service] ON [Service].[ServiceID] = [ProductService].[ServiceID]
	INNER JOIN [Reference].[ServiceType] ON [ServiceType].[ServiceTypeID] = [Service].[ServiceTypeID]
	INNER JOIN [Reference].[Product] ON [Product].[ProductID] = [ProductService].[ProductID]
	AND [ServiceCode]='CO' AND [Product].[ProductCode]='OUT'
	WHERE [Customer].[CustomerNumber] IN (SELECT [CustomerNumber] FROM @CustomerNumbers)
	ORDER BY [CustomerNumber]
END

