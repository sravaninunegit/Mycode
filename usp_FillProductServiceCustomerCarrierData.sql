	-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 30/10/2024
-- History: 30/10/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_FillProductServiceCustomerCarrierData]
	@ProductServiceCustomerCarrierData  [Customer].[ProductServiceCustomerCarrierData] READONLY
	AS
BEGIN
  MERGE INTO [Customer].[ProductServiceCustomerCarrier] AS target
USING (
    SELECT DISTINCT 
    psc.ProductServiceCustomerID,
	Psc.ProductServiceID,
    D.DayOfWeekID,
    PSCC.CarrierRouteCode,
    GETDATE() AS CreatedOn,
    PSCC.CreatedBy,
    PSCC.IsActive
FROM 
    @ProductServiceCustomerCarrierData PSCC
INNER JOIN 
    Customer.Customer C ON C.CustomerNumber = PSCC.CustomerNumber
INNER JOIN 
    Customer.ProductServiceCustomer Psc ON Psc.CustomerID = C.CustomerID
INNER JOIN 
    Reference.[DayOfWeek] D ON D.DayOfWeekCode = PSCC.DayOfWeekCode
	INNER JOIN Reference.Service s ON s.ServiceCode = PSCC. ServiceCode   
    INNER JOIN Reference.Product p ON p.ProductCode =PSCC.ProductCode
	INNER JOIN Reference.ProductService ps ON ps.ServiceID = s.ServiceID AND ps.ProductID = p.ProductID
    INNER JOIN Reference.ServiceType st ON st.ServiceTypeID = s.ServiceTypeID AND st.ServiceTypeCode =PSCC.ServiceTypeCode
WHERE 
    s.ServiceCode = PSCC.ServiceCode 
    AND p.ProductCode = PSCC.ProductCode
    AND st.ServiceTypeCode  =PSCC.ServiceTypeCode
    AND ps.ProductServiceID = psc.ProductServiceID
) AS source
ON (
    target.ProductServiceCustomerID = source.ProductServiceCustomerID
    AND target.DayOfWeekID = source.DayOfWeekID
)
WHEN MATCHED THEN
    UPDATE SET 
        target.CarrierRouteCode = source.CarrierRouteCode,
        target.CreatedOn = source.CreatedOn,
        target.CreatedBy = source.CreatedBy,
        target.IsActive = source.IsActive
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductServiceCustomerID, DayOfWeekID, CarrierRouteCode, CreatedOn, CreatedBy, IsActive)
    VALUES (source.ProductServiceCustomerID, source.DayOfWeekID, source.CarrierRouteCode, source.CreatedOn, source.CreatedBy, source.IsActive);

END;
GO
