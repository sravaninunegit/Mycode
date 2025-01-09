-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 13/11/2024
-- History: 13/11/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_UpdateStatustoInactive]
(
    @CustomerData [Customer].[CustomerData] READONLY,
    @CustomerCount INT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Drop the temporary table if it exists
    IF OBJECT_ID('tempdb..#TempCustomers') IS NOT NULL
    BEGIN
        DROP TABLE #TempCustomers;
    END

    -- Create a table to keep customers first 
    CREATE TABLE #TempCustomers (
        [CustomerNumber]    VARCHAR (17)  NOT NULL,
        [CustomerName]      VARCHAR (50)  NOT NULL, 
        [CustomerStatusCode]  [varchar](50) NOT NULL,
        [CreditLimit]       BIGINT        NULL,
        [IsActive] [bit] NOT NULL
    );

    -- Insert data into temp table
    INSERT INTO #TempCustomers
    SELECT *
    FROM @CustomerData;

    -- Create a table to store delete customers
    CREATE TABLE #DeletedCustomers (CustomerNumber VARCHAR(17));    

    IF (SELECT COUNT(1) FROM #TempCustomers) = @CustomerCount
    BEGIN 
        INSERT INTO #DeletedCustomers (CustomerNumber)
        SELECT CustomerNumber
        FROM Customer.Customer
        WHERE CustomerNumber NOT IN (SELECT CustomerNumber FROM #TempCustomers);
    END;

    -- Check if the count of #DeletedCustomers matches the count of @CustomerData
    IF (SELECT COUNT(1) FROM #DeletedCustomers) > 0
    BEGIN
        -- Update all CashProcessingOption records for the customers to be deleted
      

        UPDATE [Customer].[CashProcessingOption]
        SET IsActive = 0
        WHERE [CustomerID] IN (
            SELECT [CustomerID]
            FROM [Customer].[Customer]
            WHERE [CustomerNumber] IN (SELECT CustomerNumber FROM #DeletedCustomers));

        -- Update all ProductServiceCustomerCarrier records for the customers to be deleted
        UPDATE PSCC
        SET PSCC.IsActive = 0
        FROM [Customer].[ProductServiceCustomerCarrier] AS PSCC
        INNER JOIN [Customer].[ProductServiceCustomer] AS PSC
        ON PSCC.[ProductServiceCustomerID] = PSC.[ProductServiceCustomerID]
        INNER JOIN [Customer].[Customer] AS C
        ON PSC.[CustomerID] = C.[CustomerID]
        WHERE C.[CustomerNumber] IN (SELECT CustomerNumber FROM #DeletedCustomers);

        -- Update all ProductServiceCustomer records for the customers to be deleted
        UPDATE [Customer].[ProductServiceCustomer]
        SET IsActive = 0
        WHERE [CustomerID] IN (
            SELECT [CustomerID]
            FROM [Customer].[Customer]
            WHERE [CustomerNumber] IN (SELECT CustomerNumber FROM #DeletedCustomers));

        -- Update all Cassette records for the customers to be deleted
        UPDATE CS
        SET CS.IsActive = 0
        FROM [Customer].[Cassette] AS CS
        INNER JOIN [Customer].[RemoteDevice] AS RD
        ON RD.[RemoteDeviceID] = CS.[RemoteDeviceID]
        INNER JOIN [Customer].[Customer] AS C
        ON C.[CustomerID] = RD.[CustomerID]
        WHERE C.[CustomerNumber] IN (SELECT CustomerNumber FROM #DeletedCustomers);

        -- Update all Remote Device records for the customers to be deleted
        UPDATE RD
        SET RD.IsActive = 0
        FROM [Customer].[RemoteDevice] AS RD
        INNER JOIN [Customer].[Customer] AS C
        ON C.[CustomerID] = RD.[CustomerID]
        WHERE C.[CustomerNumber] IN (SELECT CustomerNumber FROM #DeletedCustomers);

        -- Update all Customer records for the customers to be deleted
        UPDATE [Customer].[Customer]
        SET IsActive = 0
        WHERE [CustomerNumber] IN (SELECT CustomerNumber FROM #DeletedCustomers);
    END;    
END;
GO