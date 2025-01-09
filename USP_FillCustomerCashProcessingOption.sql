-- ==================================================================
-- Author:      Resource 504141

-- History: 12/11/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_FillCustomerCashProcessingOption]
    @CustomerCashProcessingOptions [Customer].[CustomerCashProcessingOption] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    -- Merging data into CashProcessingOption table
   MERGE INTO [Customer].[CashProcessingOption] AS target
USING (
   SELECT DISTINCT
    psc.ProductServiceID,
    c.CustomerID,
    CPO.CashProcessingRuleID,
    CPO.CashProcessingOptionValue,
    CPO.[CreatedBy],
    CPO.IsActive   
FROM
    @CustomerCashProcessingOptions CPO
    INNER JOIN [Customer].[Customer] c ON c.[CustomerNumber] = CPO.[CustomerNumber]
    INNER JOIN Reference.CashProcessingRule CR ON CR.CashProcessingRuleCode = CPO.[CashProcessingRuleCode]
    INNER JOIN Customer.ProductServiceCustomer psc ON psc.CustomerID = c.CustomerID
    INNER JOIN Reference.Service s ON s.ServiceCode = CPO.ServiceCode    
    INNER JOIN Reference.Product p ON p.ProductCode = CPO.ProductCode
	INNER JOIN Reference.ProductService ps ON ps.ServiceID = s.ServiceID AND ps.ProductID = p.ProductID
    INNER JOIN Reference.ServiceType st ON st.ServiceTypeID = s.ServiceTypeID AND st.ServiceTypeCode = CPO.ServiceTypeCode
WHERE 
    s.ServiceCode = CPO.ServiceCode  
    AND p.ProductCode = CPO.ProductCode 
    AND st.ServiceTypeCode = CPO.ServiceTypeCode
    AND ps.ProductServiceID = psc.ProductServiceID 
) AS source
ON (
    target.CashProcessingRuleID = source.CashProcessingRuleID
    AND target.ProductServiceID = source.ProductServiceID
	AND target.CustomerID=source.CustomerID
)
WHEN MATCHED THEN
    UPDATE SET        
        target.CashProcessingRuleID = source.CashProcessingRuleID,
        target.ProductServiceID = source.ProductServiceID,
        target.CustomerID = source.CustomerID,
        target.CashProcessingOptionValue = source.CashProcessingOptionValue		
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CashProcessingRuleID,ProductServiceID, CustomerID, CashProcessingOptionValue,CreatedBy, CreatedOn,IsActive)
    VALUES (source.CashProcessingRuleID, source.ProductServiceID, source.CustomerID, source.CashProcessingOptionValue,source.CreatedBy, GETDATE(),source.IsActive);

END;
GO
