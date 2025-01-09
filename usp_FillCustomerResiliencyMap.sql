
-- ==================================================================
-- Author:      Resource 504141
-- updated Date: 07/11/2024
-- History: 07/11/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_FillCustomerResiliencyMap]
    @CustomerResiliencyData [Customer].[CustomerResiliency] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    -- Merging data into CustomerResiliencyMap table
    MERGE [Customer].[CustomerResiliencyMap] AS CRM
    USING @CustomerResiliencyData AS CR
    ON CRM.OrganisationID = (SELECT OrganisationID FROM [Customer].[Organisation] WHERE OrganisationName = CR.OrganisationName)
    AND CRM.CustomerLocationID = CR.CustomerLocationID
    WHEN MATCHED THEN
        UPDATE SET CRM.CustomerNumber = CR.CustomerNumber,
                   CRM.CreatedBy = SYSTEM_USER,
                   CRM.CreatedOn = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (OrganisationID, CustomerLocationID, CustomerNumber, CreatedBy, CreatedOn)
        VALUES ((SELECT OrganisationID FROM [Customer].[Organisation] WHERE OrganisationName = CR.OrganisationName),
                CR.CustomerLocationID,
                CR.CustomerNumber,
                SYSTEM_USER,
                GETDATE());

END;
GO
