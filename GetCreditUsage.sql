-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 20/08/2024
-- Description: Return orders for org that have delivery date >=given date.
-- History: 27/08/2024 : Resource 503436 : SOTPT-264
-- History: 18/10/2024 : Resource 503436 : SOTPT-726
-- ==================================================================
CREATE PROCEDURE [CCORF].[GetCreditUsage]
(
	@OrgCode VARCHAR(17),
	@Today DATE
)
AS
BEGIN
	SELECT [Order].[DeliveryDate] AS 'DeliveryDate', SUM([OrderValue]) TotalOnDeliveryDate FROM [Orders].[Order]
	INNER JOIN [Customer].[CustomerResiliencyMap] ON [Order].[LocationID] = [CustomerResiliencyMap].[CustomerLocationID]
	INNER JOIN [Customer].[Organisation] ON [CustomerResiliencyMap].[OrganisationID] = [Organisation].[OrganisationID]
	WHERE [Order].[IsActive] = 1 AND [CustomerResiliencyMap].[IsActive] = 1 AND [Organisation].[IsActive] = 1 AND RIGHT(REPLICATE('0', 17) + [Organisation].[OrganisationIdentifier], 17) = @OrgCode AND [Order].[DeliveryDate] >= @Today
	GROUP BY [DeliveryDate]
END
