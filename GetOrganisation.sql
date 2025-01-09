-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 08/08/2024
-- Description: Get organisation data by 17-digit org. ID.
-- History: 08/08/2024 : Resource 503436 : SOTPT-264
-- ==================================================================
CREATE PROCEDURE [CCORF].[GetOrganisation]
(
    @OrganisationIdentifier CHAR(17)
)
AS
BEGIN
	SELECT [OrganisationIdentifier], [OrganisationName], [CreditLimit] FROM [Customer].[Organisation]
	WHERE [Customer].[Organisation].[IsActive] = 1 AND RIGHT(REPLICATE('0', 17) + [OrganisationIdentifier], 17)=@OrganisationIdentifier
END
