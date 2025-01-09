
-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 12/11/2024
-- History: 12/11/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_FillCustomer]
	 @CustomerData [Customer].[CustomerData] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    -- Merging data into Customer table
    MERGE [Customer].[Customer] AS T
    USING (
        SELECT CD.CustomerNumber,
               CD.CustomerName,
               CR.CustomerStatusID,
               CD.CreditLimit,
               CD.IsActive
        FROM @CustomerData CD
        INNER JOIN [Reference].[CustomerStatus] CR ON CR.CustomerStatusCode = CD.CustomerStatusCode
    ) AS S
    ON 
        T.CustomerNumber = S.CustomerNumber
    WHEN MATCHED THEN
        UPDATE SET T.CustomerNumber = S.CustomerNumber,
                   T.CustomerStatusID = S.CustomerStatusID,
                   T.CustomerName = S.CustomerName,
                   T.CreditLimit = S.CreditLimit                  
    WHEN NOT MATCHED THEN
        INSERT (CustomerNumber,CustomerName,CustomerStatusID,CreditLimit,IsActive)
        VALUES (S.CustomerNumber, S.CustomerName, S.CustomerStatusID, S.CreditLimit,S.IsActive);
        
END;
GO