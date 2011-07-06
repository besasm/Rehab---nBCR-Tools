USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_COSTSBYDIAMETERANDMATERIAL]    Script Date: 06/28/2011 16:29:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [ROSE\issacg].[USP_REHAB_COSTSBYDIAMETERANDMATERIAL]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @theQuery nvarchar(max)
DECLARE @theIterator int

SET @theIterator = 0
SET @theQuery = 'SELECT SUM(CAST(replacecost AS float)) AS Total_replace_cost, Dia, SUM(csp) as csp, SUM(csplength) as cspft, SUM(rcp) as rcp, SUM(rcplength) as rcpft, SUM(vsp) as vsp, SUM(vsplength) as vspft, SUM(pvc) as pvc, SUM(pvclength) as pvcft, SUM(mono) as mono, SUM(monolength) as monoft, SUM(brick) as brick, SUM(bricklength) as brickft,SUM(others) as others, SUM(otherslength) as othersft '
WHILE @theIterator < 6
BEGIN
	--SET @theQuery = @theQuery + ',SUM(CAST([' + convert(nvarchar(10), @theIterator) + '] AS float)) AS [' + convert(nvarchar(10), @theIterator) + ']'
	--SET @theQuery = @theQuery + ',SUM(CAST([' + convert(nvarchar(10), @theIterator) + 'length] AS float)) AS [' + convert(nvarchar(10), @theIterator) + 'length]'
	
	SET @theIterator = @theIterator + 1
END

SET @theQuery = @theQuery + 'FROM (SELECT replacecost, CASE WHEN diamwidth <= 12 THEN ''<= 12'' WHEN diamwidth <= 18 AND diamwidth > 12 THEN ''>12 <= 18'' WHEN diamwidth <= 24 AND diamwidth > 18 THEN ''>18 <= 24'' WHEN diamwidth <= 36 AND diamwidth > 24 THEN ''>24 <= 36'' WHEN diamwidth <= 54 AND diamwidth > 36 THEN ''>36 <= 54'' ELSE ''>54'' END AS Dia'
--SET @theIterator = 0
--WHILE @theIterator < 6
--BEGIN
--CSP
	SET @theQuery = @theQuery + ', CASE WHEN material = ''CSP'' THEN replacecost ELSE 0 END AS [CSP]'
	SET @theQuery = @theQuery + ', CASE WHEN material = ''CSP'' THEN length ELSE 0 END AS [CSPlength]'
--RCP
	SET @theQuery = @theQuery + ', CASE WHEN material = ''RCP'' THEN replacecost ELSE 0 END AS [RCP]'
	SET @theQuery = @theQuery + ', CASE WHEN material = ''RCP'' THEN length ELSE 0 END AS [RCPlength]'
--VCP
	SET @theQuery = @theQuery + ', CASE WHEN material = ''VSP'' THEN replacecost ELSE 0 END AS [VSP]'
	SET @theQuery = @theQuery + ', CASE WHEN material = ''VSP'' THEN length ELSE 0 END AS [VSPlength]'
--PVC
	SET @theQuery = @theQuery + ', CASE WHEN material = ''PVC'' THEN replacecost ELSE 0 END AS [PVC]'
	SET @theQuery = @theQuery + ', CASE WHEN material = ''PVC'' THEN length ELSE 0 END AS [PVClength]'
--MONO
	SET @theQuery = @theQuery + ', CASE WHEN material = ''MONO'' THEN replacecost ELSE 0 END AS [MONO]'
	SET @theQuery = @theQuery + ', CASE WHEN material = ''MONO'' THEN length ELSE 0 END AS [MONOlength]'
--BRICK
	SET @theQuery = @theQuery + ', CASE WHEN material = ''BRICK'' THEN replacecost ELSE 0 END AS [BRICK]'
	SET @theQuery = @theQuery + ', CASE WHEN material = ''BRICK'' THEN length ELSE 0 END AS [BRICKlength]'
--OTHERS
	SET @theQuery = @theQuery + ', CASE WHEN (material <> ''CSP'' AND material <> ''RCP'' AND material <> ''VSP'' AND material <> ''PVC'' AND material <> ''MONO'' AND material <> ''BRICK'') THEN replacecost ELSE 0 END AS [OTHERS]'
	SET @theQuery = @theQuery + ', CASE WHEN (material <> ''CSP'' AND material <> ''RCP'' AND material <> ''VSP'' AND material <> ''PVC'' AND material <> ''MONO'' AND material <> ''BRICK'') THEN length ELSE 0 END AS [OTHERSlength]'
	--SET @theIterator = @theIterator + 1
--END
SET @theQuery = @theQuery + 'FROM GIS.REHAB10FTSEGS WHERE (mlinkid < 40000000) and REMARKS = ''BES'') AS derivedtbl_1 GROUP BY Dia'

     Exec sp_Executesql @theQuery                  
END
