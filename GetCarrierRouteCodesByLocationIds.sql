-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 02/09/2024
-- Description: Get carriers for location.
-- History: 20/08/2024 : Resource 503436 : SOTPT-264
-- ==================================================================
CREATE PROCEDURE [CCORF].[GetCarrierRouteCodesByLocationIds]
(
	@OrgCode CHAR(17),
	@Locations [CCORF].[LocationIdList] READONLY
)
AS
BEGIN
	SELECT [LocationId],[Customer].[CustomerNumber],CarrierRouteCode,DayOfWeekCode,ServiceTypeCode FROM [Customer].[ProductServiceCustomerCarrier] 
	inner join [Customer].[ProductServiceCustomer] 	on [ProductServiceCustomerCarrier].[ProductServiceCustomerID]=[ProductServiceCustomer].ProductServiceCustomerID
	inner join [Reference].[DayOfWeek]  on [DayOfWeek].DayOfWeekID=[ProductServiceCustomerCarrier].[DayOfWeekID]
	inner join [Customer].[Customer] on [ProductServiceCustomer].[CustomerID]=[Customer].[CustomerID]	
	Inner join [Reference].[ProductService] on [ProductService].[ProductServiceID]=[ProductServiceCustomer].[ProductServiceID]
	inner join Reference.[Service]	on [Service].[ServiceID]=[ProductService].[ServiceID]
	inner join [Reference].[ServiceType] on [ServiceType].[ServiceTypeID]=[Service].[ServiceTypeID]
	inner join [Customer].[CustomerResiliencyMap] 	on [CustomerResiliencyMap].[CustomerNumber]=[Customer].[CustomerNumber]
	INNER JOIN [Customer].[Organisation] ON [Organisation].[OrganisationID]=[CustomerResiliencyMap].[OrganisationID]
	INNER JOIN @Locations on [@Locations].[LocationId]=[CustomerResiliencyMap].[CustomerLocationID]
	WHERE RIGHT(REPLICATE('0', 17) + [OrganisationIdentifier], 17) = @OrgCode
END
