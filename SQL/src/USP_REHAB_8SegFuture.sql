USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_8SegFuture]    Script Date: 06/28/2011 16:27:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [ROSE\issacg].[USP_REHAB_8SegFuture]  --(@Compkey int)
AS
BEGIN

DECLARE @thisCompkey        int
DECLARE @iterativeYear      float
DECLARE @replaceYear        float
DECLARE @rValue             float
DECLARE @yearExponent       float
DECLARE @replaceSDev        float
DECLARE @thisYear			float
DECLARE @ReplaceYear_Whole  float
DECLARE @iterativeColumn	int
DECLARE @SQL				nchar(4000)
--
DELETE FROM REHAB_SegFuture
--
SET @ReplaceYear = 2040.00
SET @ReplaceYear_Whole = 2130
SET @ReplaceSDev = 12.00
SET @thisYear = 2010.00

DECLARE @columnName			nchar(6)
DECLARE @interestValue      float

SET @thisYear = 2010.00
SET @iterativeYear = 2010
SET @iterativeColumn = 14

WHILE @iterativeYear <= 2130
BEGIN
--
INSERT INTO REHAB_SegFuture SELECT COMPKEY, MLinkID, Std_dev_seg, Fail_Yr_seg, cof, @iterativeYear, cof * [ROSE\issacg].gv(convert(numeric(12,2),@iterativeYear),Fail_Yr_seg ,Std_dev_seg,1)
FROM [SANDBOX].[GIS].[REHAB10FTSEGS] WHERE MLINKID >= 40000000 
AND REMARKS = 'BES' 
AND ReplaceCost <> 0 
AND Std_dev_seg <> 0
AND Fail_yr_seg <> 0
and replaceCost <> 0
and cof <>0

SET @iterativeYear = @iterativeYear + 1
--
END

--Get the accumulated risk inspect year
UPDATE [SANDBOX].[GIS].[REHAB10FTSEGS] SET [SANDBOX].[GIS].[REHAB10FTSEGS].ACCUM_RISK_INSPECT_YEAR = C.ACCUM_RISK_INSPECT_YEAR
FROM
(
SELECT [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY, MIN(Year) AS ACCUM_RISK_INSPECT_YEAR FROM
[SANDBOX].[GIS].[REHAB10FTSEGS] INNER JOIN
(
SELECT Compkey, Year, SUM(bpw) AS BPW FROM REHAB_SegFuture GROUP BY COMPKEY, YEAR
) AS A ON [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY = A.COMPKEY AND
MLinkID <40000000 AND
A.BPW > CASE WHEN DiamWidth <=36 THEN [Length]*1.5 ELSE [Length] * 5 END
GROUP BY [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY
) AS C INNER JOIN [SANDBOX].[GIS].[REHAB10FTSEGS] ON C.COMPKEY = [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY AND MLinkID <40000000

--Get the accumulated risk replace year
UPDATE [SANDBOX].[GIS].[REHAB10FTSEGS] SET [SANDBOX].[GIS].[REHAB10FTSEGS].ACCUM_RISK_REPLACE_YEAR = C.ACCUM_RISK_REPLACE_YEAR
FROM
(
SELECT [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY, MIN(Year) AS ACCUM_RISK_REPLACE_YEAR FROM
[SANDBOX].[GIS].[REHAB10FTSEGS] INNER JOIN
(
SELECT Compkey, Year, SUM(bpw) AS BPW FROM REHAB_SegFuture GROUP BY COMPKEY, YEAR
) AS A ON [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY = A.COMPKEY AND
MLinkID <40000000 AND
A.BPW > Replacecost
GROUP BY [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY
) AS C INNER JOIN [SANDBOX].[GIS].[REHAB10FTSEGS] ON C.COMPKEY = [SANDBOX].[GIS].[REHAB10FTSEGS].COMPKEY AND MLinkID <40000000


END