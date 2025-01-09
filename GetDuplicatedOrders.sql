-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 22/08/2024
-- Description: Return list of CCORF orders that already exist (duplicates).
-- History: 22/08/2024 : Resource 503436 : SOTPT-264
-- History: 17/10/2024 : Resource 503436 : SOTPT-776
-- ==================================================================
CREATE PROCEDURE [CCORF].[GetDuplicatedOrders]
(
	@OrgCode VARCHAR(17),
	@Existing [CCORF].[GetDuplicatedOrdersList] READONLY
)
AS
BEGIN
	SELECT [@Existing].[RowId], [@Existing].[LocationId], [@Existing].[DeliveryDate], [@Existing].[OrderType] FROM [Orders].[Order]
	INNER JOIN [Customer].[CustomerResiliencyMap] ON [CustomerResiliencyMap].[CustomerResiliencyMapID] = [Order].[LocationID]
	INNER JOIN [Customer].[Organisation] ON [Organisation].[OrganisationID] = [CustomerResiliencyMap].[OrganisationID]
	INNER JOIN @Existing ON [@Existing].[LocationId] = [CustomerResiliencyMap].[CustomerLocationID] AND [@Existing].[DeliveryDate] = [Order].[DeliveryDate]
	WHERE
		[Organisation].[OrganisationIdentifier] = @OrgCode AND [Order].[IsActive] = 1 AND [CustomerResiliencyMap].[IsActive] = 1 AND [Organisation].IsActive = 1
END
