-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 30/10/2024
-- History: 30/10/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_FillCassetteData]
    @CassetteData [Customer].[CassetteData] READONLY
AS
BEGIN
    SET NOCOUNT ON;
    -- Insert new records, ignoring duplicates
    MERGE INTO [Customer].[Cassette] AS target
USING (
    SELECT 
        RD.RemoteDeviceID,
        D.DenominationID,
        I.IssuerID,
        Cr.CurrencyID,
        T.CassetteNumber,
        T.CreatedBy,
        GETDATE() AS CreatedOn,
        T.IsActive
    FROM 
        @CassetteData T 
    INNER JOIN 
        Customer.Customer c ON c.CustomerNumber = T.CustomerNumber 
    INNER JOIN 
        Customer.RemoteDevice RD ON RD.CustomerID = c.CustomerID
    INNER JOIN 
        Reference.Currency Cr ON Cr.CurrencyCode = T.CurrencyCode
    INNER JOIN 
        Reference.Issuer I ON I.IssuerCode = T.IssuerCode
    INNER JOIN 
        Reference.Denomination D ON D.DenominationCode = T.DenominationCode 
) AS source
ON (
    target.RemoteDeviceID = source.RemoteDeviceID
    AND target.CassetteNumber = source.CassetteNumber
)
WHEN MATCHED THEN
    UPDATE SET 
        target.DenominationID = source.DenominationID,
        target.IssuerID = source.IssuerID,
        target.CurrencyID = source.CurrencyID,
        target.CreatedBy = source.CreatedBy,
        target.CreatedOn = source.CreatedOn,
        target.IsActive = source.IsActive
WHEN NOT MATCHED BY TARGET THEN
    INSERT (RemoteDeviceID, DenominationID, IssuerID, CurrencyID, CassetteNumber, CreatedBy, CreatedOn, IsActive)
    VALUES (source.RemoteDeviceID, source.DenominationID, source.IssuerID, source.CurrencyID, source.CassetteNumber, source.CreatedBy, source.CreatedOn, source.IsActive);

END;
GO

