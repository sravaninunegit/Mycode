-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 30/10/2024
-- History: 30/10/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_FillProductServiceCustomerData]
	@ProductServiceCustomerData  [Customer].[ProductServiceCustomerData] READONLY
	AS
BEGIN
    SET NOCOUNT ON;
   MERGE INTO [Customer].[ProductServiceCustomer] AS target
USING (
    SELECT DISTINCT 
        c.CustomerID,
        ps.ProductServiceID,
        psc.CashCentreCode,
        psc.ClientCode,
        psc.CreatedBy,
        GETDATE() AS CreatedOn,
        psc.IsActive
    FROM 
       @ProductServiceCustomerData psc
    INNER JOIN 
        Customer.Customer c ON c.CustomerNumber = psc.CustomerNumber
    INNER JOIN 
        Reference.Service s ON s.ServiceCode = psc.ServiceCode
    INNER JOIN 
        Reference.ProductService ps ON ps.ServiceID = s.ServiceID
    INNER JOIN 
        Reference.Product p ON p.ProductID = ps.ProductID
    INNER JOIN 
        Reference.ServiceType st ON st.ServiceTypeID = s.ServiceTypeID
    WHERE 
        s.ServiceCode = psc.ServiceCode  
        AND p.ProductCode = psc.ProductCode 
        AND st.ServiceTypeCode = psc.ServiceTypeCode
) AS source
ON (
    target.ProductServiceID = source.ProductServiceID
    AND target.CustomerID = source.CustomerID
    AND target.CashCentreCode = source.CashCentreCode
)
WHEN MATCHED THEN
    UPDATE SET 
        target.ISAClientCode = source.ClientCode,
        target.CreatedBy = source.CreatedBy,
        target.CreatedOn = source.CreatedOn,
        target.IsActive = source.IsActive
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CustomerID, ProductServiceID, CashCentreCode, ISAClientCode, CreatedBy, CreatedOn, IsActive)
    VALUES (source.CustomerID, source.ProductServiceID, source.CashCentreCode, source.ClientCode, source.CreatedBy, source.CreatedOn, source.IsActive);
END;
GO