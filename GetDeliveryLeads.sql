-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 20/08/2024
-- Description: Return list of CCORF locations, their delivery lead times, and the centre codes.
-- History: 20/08/2024 : Resource 503436 : SOTPT-264
-- History: 14/11/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [CCORF].[GetDeliveryLeads]
(
	@OrgCode CHAR(17),
	@Locations [CCORF].[LocationIdList] READONLY
)
AS
BEGIN
	SELECT [LocationId], [CashProcessingOptionValue] AS DeliveryLead, CashCentreCode FROM [Customer].[CashProcessingOption]
	INNER JOIN [Customer].[Customer] on [Customer].[CustomerID]=[CashProcessingOption].[CustomerID]
	INNER JOIN [Customer].[CustomerResiliencyMap] ON [CustomerResiliencyMap].[CustomerNumber]=[Customer].[CustomerNumber]
	INNER JOIN [Customer].[Organisation] ON [Organisation].[OrganisationID]=[CustomerResiliencyMap].[OrganisationID]
	INNER JOIN [Customer].ProductServiceCustomer on ProductServiceCustomer.CustomerID=Customer.CustomerID
	INNER JOIN [Reference].CashProcessingRule on CashProcessingRule.CashProcessingRuleID = CashProcessingOption.CashProcessingRuleID
	INNER JOIN @Locations on [@Locations].LocationId=[CustomerResiliencyMap].[CustomerLocationID]
	WHERE RIGHT(REPLICATE('0', 17) + [OrganisationIdentifier], 17) = @OrgCode and CashProcessingRuleCode='CAP0013'
	-- todo: put in IsActive checks
END
