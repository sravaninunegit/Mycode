-- ==================================================================
-- Author:      Resource 504141
-- Create Date: 30/10/2024
-- History: 30/10/2024 : Resource 504141 : SOTPT-802
-- ==================================================================
CREATE PROCEDURE [Customer].[usp_FillRemoteDeviceData]
	@RemoteDeviceData  [Customer].[RemoteDeviceData] READONLY
	AS
BEGIN
    SET NOCOUNT ON;
   MERGE INTO [Customer].[RemoteDevice] AS target
USING (
    SELECT  
        C.CustomerID, 
        RDM.RemoteDeviceModelID,
        CT.CassetteTypeID,
        RD.IsDyeCassette,
        RD.MaxNotes,
        RD.CreatedBy,
        GETDATE() AS CreatedOn,
        RD.IsActive
    FROM 
        @RemoteDeviceData RD
    INNER JOIN 
        Customer.Customer C ON C.CustomerNumber = RD.CustomerNumber
    INNER JOIN  
        Reference.RemoteDeviceModel RDM ON RDM.RemoteDeviceModelCode = RD.RemoteDeviceModelCode
    INNER JOIN  
        Reference.RemoteDeviceManufacturer RDMF ON RDMF.RemoteDeviceManufacturerID = RDM.RemoteDeviceManufacturerID
    INNER JOIN 
        Reference.CassetteType CT ON CT.CassetteTypeCode = RD.CassetteTypeCode
    WHERE 
        RD.IsActive = 1 
        AND RDMF.RemoteDeviceManufacturerCode = RD.RemoteDeviceManufacturerCode
) AS source
ON target.CustomerID = source.CustomerID
WHEN MATCHED THEN
    UPDATE SET 
        target.RemoteDeviceModelID = source.RemoteDeviceModelID,
        target.CassetteTypeID = source.CassetteTypeID,
        target.IsDyeCassette = source.IsDyeCassette,
        target.MaxNotes = source.MaxNotes,
        target.CreatedBy = source.CreatedBy,
        target.CreatedOn = source.CreatedOn,
        target.IsActive = source.IsActive
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CustomerID, RemoteDeviceModelID, CassetteTypeID, IsDyeCassette, MaxNotes, CreatedBy, CreatedOn, IsActive)
    VALUES (source.CustomerID, source.RemoteDeviceModelID, source.CassetteTypeID, source.IsDyeCassette, source.MaxNotes, source.CreatedBy, source.CreatedOn, source.IsActive);


END;
GO