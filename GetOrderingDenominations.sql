-- ==================================================================
-- Author:      Resource 503436
-- Create Date: 08/08/2024
-- Description: Return ordering denomination codes with CCORF fitness. Changes "103" into "003".
-- History: 13/08/2024 : Resource 503436 : SOTPT-264
-- ==================================================================
CREATE PROCEDURE [CCORF].[GetOrderingDenominations]
AS
BEGIN
	DECLARE @Fitness TABLE (FitnessCode CHAR(3))
	INSERT INTO @Fitness Values ('103'),('004'),('009'),('007')

	SELECT LEFT(ProductCode, LEN(ProductCode) - 3) AS 'DenominationCode', CASE WHEN SUBSTRING(ProductCode,4,1)='N' THEN 1 ELSE 0 END AS 'Notement', Description, CASE WHEN FitnessCode='103' THEN '003' ELSE FitnessCode END AS 'FitnessCode', CAST(Value * 100 AS INT) Value, Package1, Package2, Package3 FROM [Reference].[OrderingDenominations]
	INNER JOIN [Reference].[Media] ON [OrderingDenominations].Code = LEFT(ProductCode, LEN(ProductCode) - 3)
	CROSS APPLY @Fitness
	WHERE RIGHT(ProductCode,3)=FitnessCode
END
