USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_LENGTHBYYEARBUILTANDMATERIAL]    Script Date: 06/28/2011 16:34:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [ROSE\issacg].[USP_REHAB_LENGTHBYYEARBUILTANDMATERIAL]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @theQuery nvarchar(max)
DECLARE @theIterator int

SET @theIterator = 1880
SET @theQuery = 'SELECT SUM(CAST(replacecost AS float)) AS Total_replace_cost, material'
WHILE @theIterator < 2011
BEGIN
	--SET @theQuery = @theQuery + ',SUM(CAST([' + convert(nvarchar(10), @theIterator) + '] AS float)) AS [' + convert(nvarchar(10), @theIterator) + ']'
	SET @theQuery = @theQuery + ',SUM(CAST([' + convert(nvarchar(10), @theIterator) + 'length] AS float)) AS [' + convert(nvarchar(10), @theIterator) + 'length]'
	SET @theIterator = @theIterator + 5
END

SET @theQuery = @theQuery + 'FROM (SELECT replacecost, material'
SET @theIterator = 1880
WHILE @theIterator < 2011
BEGIN
	SET @theQuery = @theQuery + ', CASE WHEN YEAR(instdate) >= '+convert(nvarchar(10), @theIterator) +' AND YEAR(instdate) < '+convert(nvarchar(10), @theIterator+5) +' THEN replacecost ELSE 0 END AS [' + convert(nvarchar(10), @theIterator) + ']'
	SET @theQuery = @theQuery + ', CASE WHEN YEAR(instdate) >= '+convert(nvarchar(10), @theIterator) +' AND YEAR(instdate) < '+convert(nvarchar(10), @theIterator+5) +' THEN length ELSE 0 END AS [' + convert(nvarchar(10), @theIterator) + 'length]'
	SET @theIterator = @theIterator + 5
END
SET @theQuery = @theQuery + 'FROM GIS.REHAB10FTSEGS WHERE (mlinkid < 40000000) and remarks = ''BES'') AS derivedtbl_1 GROUP BY material'

     Exec sp_Executesql @theQuery
                  
END
