﻿-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 08/08/2024
-- Description: Get location details for a CCORF org.
-- History: 08/08/2024 : Resource 503436 : SOTPT-264
-- ==================================================================
CREATE PROCEDURE [Customer].[GetLocationsForOrg]
(
    @OrganisationIdentifier CHAR(17)
)
AS
BEGIN
    SELECT [CustomerLocationID], [CustomerNumber] FROM [Customer].[CustomerResiliencyMap]
    INNER JOIN [Customer].[Organisation] on [Organisation].[OrganisationID] = [CustomerResiliencyMap].[OrganisationID]
    WHERE [Customer].[Organisation].[IsActive] = 1 AND [Customer].[CustomerResiliencyMap].[IsActive] = 1 AND RIGHT(REPLICATE('0', 17) + [OrganisationIdentifier], 17) = @OrganisationIdentifier
END
GO