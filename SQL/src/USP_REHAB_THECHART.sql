USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_THECHART]    Script Date: 06/28/2011 16:37:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [ROSE\issacg].[USP_REHAB_THECHART] AS
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
--Declare @columnName			nchar(4)
DECLARE @SQL				nchar(4000)

DELETE FROM REHAB_JoesChartData
DELETE FROM REHAB_JoesChartDataCheck

INSERT INTO REHAB_JoesChartData SELECT COMPKEY, MLinkID, [ACTION], 0, (ReplaceCost/(CASE WHEN Seg_Count = 0 THEN 1 ELSE Seg_Count END)) AS CostToReplaceASegment, (CASE WHEN ACTION = 3 THEN Fail_Near ELSE 0 END) AS CountOfSegmentsToReplace, (CASE WHEN ACTION = 3 then 12 ELSE CASE WHEN ACTION = 2 OR ACTION = 6 OR ACTION = 7 OR ACTION = 8 THEN 12 ELSE Std_dev END END) AS WholePipeStdDev, /*(CASE WHEN ACTION = 3 THEN (CASE WHEN Fail_Yr < 2050 THEN Fail_Yr ELSE 2050 END) ELSE Fail_Yr END)*/(CASE WHEN ACTION = 3 THEN 2040 ELSE CASE WHEN ACTION = 2 OR ACTION = 6 OR ACTION = 7 OR ACTION = 8 THEN 2010 ELSE Fail_Yr END END) AS WholePipeReplaceYear, ReplaceCost AS WholePipeReplaceCost, DiamWidth AS PipeSize, Grade_H5 AS PIPEGRADE,
(ReplaceCost/(CASE WHEN Seg_Count = 0 THEN 1 ELSE Seg_Count END))*(CASE WHEN ACTION = 3 THEN Fail_Near ELSE 0 END),
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0,0,
0,0,0
FROM [SANDBOX].[GIS].[REHAB10FTSEGS_BES] WHERE MLINKID < 40000000 AND COMPKEY <> 0 AND REMARKS = 'BES' AND COMPKEY NOT IN 
--dont let any whole pipes in that have more than one record based on compkey
(SELECT COMPKEY FROM (SELECT COMPKEY, COUNT(*) AS THECOUNT FROM [SANDBOX].[GIS].[REHAB10FTSEGS_BES] WHERE MLINKID < 40000000 AND COMPKEY <> 0 GROUP BY COMPKEY ) AS A WHERE THECOUNT > 1)

UPDATE REHAB_JoesChartData SET JobNo = 1    FROM REHAB_JoesChartData INNER JOIN [SANDBOX].[GIS].[REHAB10FTSEGS_BES] ON REHAB_JoesChartData.COMPKEY = [SANDBOX].[GIS].[REHAB10FTSEGS_BES].COMPKEY WHERE [SANDBOX].[GIS].[REHAB10FTSEGS_BES].[ACTION] = 3--(CountOfSegmentsToReplace > 0 AND CountOfSegmentsToReplace/(CASE WHEN Seg_Count = 0 THEN 1 ELSE Seg_Count END) < .1 ) OR (CountOfSegmentsToReplace =1 AND CountOfSegmentsToReplace/(CASE WHEN Seg_Count = 0 THEN 1 ELSE Seg_Count END) >= .1 )
UPDATE REHAB_JoesChartData SET JobNo = 8400 WHERE COMPKEY IN (SELECT COMPKEY FROM REHAB_tblProject8400)
UPDATE REHAB_JoesChartData SET JobNo = 4863 WHERE COMPKEY IN (SELECT COMPKEY FROM REHAB_tblProject4863)

SET @ReplaceYear = 2040.00
SET @ReplaceYear_Whole = 2130
SET @ReplaceSDev = 12.00
SET @thisYear = 2010.00

--UPDATE REHAB_JoesChartData SET [2010] = WholePipeReplaceCost * A FROM REHAB_JoesChartData INNER JOIN REHAB_NormalDistribution  ON Z = CASE WHEN ROUND((@thisYear-WholePipeReplaceYear)/WholePipeStdDev,2) < -3 THEN -4
--                                                                                                                               WHEN ROUND((@thisYear-WholePipeReplaceYear)/WholePipeStdDev,2) >  3 THEN  4
--                                                                                                                               ELSE ROUND((@thisYear-WholePipeReplaceYear)/WholePipeStdDev,2) END
UPDATE REHAB_JoesChartData SET [2010] = WholePipeReplaceCost * [ROSE\issacg].gv(@thisYear,WholePipeReplaceYear ,(CASE WHEN WholePipeStdDev = 0 THEN 1 ELSE WholePipeStdDev END),1) --WHERE ACTION <>2--/WholePipeStdDev
--UPDATE REHAB_JoesChartData SET [2010] = [2010]+ WholePipeReplaceCost WHERE ACTION = 2--/WholePipeStdDev

--UPDATE  #UnitMultiplierTable SET unit_multiplier = ISNULL(unit_multiplier, 0)+@yearExponent * [ROSE\issacg].gv(@iterativeYear,Failure_Yr ,Std_Dev,0)/std_dev

DECLARE @columnName			nchar(6)
DECLARE @interestValue      float

SET @thisYear = 2010.00
SET @interestValue = 1.025
SET @iterativeYear = 2011
SET @iterativeColumn = 14

WHILE @iterativeYear <= 2060
BEGIN

Select @columnName = Column_Name from Information_Schema.columns 
where Ordinal_position = @iterativeColumn and Table_Name = 'REHAB_JoesChartData'


SET    @yearExponent = Power(@interestValue, @thisYear - @iterativeYear)
Set @SQL  = '
UPDATE REHAB_JoesChartData SET ['+@columnName+'] = ' + convert(varchar(10), convert(numeric(12,2), @yearExponent))+ ' * WholePipeReplaceCost * (ISNULL(P,0)/(CASE WHEN WholePipeStdDev = 0 THEN 1 ELSE WholePipeStdDev END)) FROM REHAB_JoesChartData INNER JOIN REHAB_NormalDistribution  ON Z = CASE WHEN ROUND(('+convert(varchar(10), convert(numeric(12,2),@iterativeYear))+'-convert(numeric(12,2),WholePipeReplaceYear))/convert(numeric(12,2),(CASE WHEN WholePipeStdDev = 0 THEN 1 ELSE WholePipeStdDev END)),2) < -3 THEN -4
                                                                                                                                                                                    WHEN ROUND(('+convert(varchar(10), convert(numeric(12,2),@iterativeYear))+'-convert(numeric(12,2),WholePipeReplaceYear))/convert(numeric(12,2),(CASE WHEN WholePipeStdDev = 0 THEN 1 ELSE WholePipeStdDev END)),2) >  3 THEN  4
                                                                                                                                                                                    ELSE ROUND(('+convert(varchar(10), convert(numeric(12,2),@iterativeYear))+'-convert(numeric(12,2),WholePipeReplaceYear))/convert(numeric(12,2),(CASE WHEN WholePipeStdDev = 0 THEN 1 ELSE WholePipeStdDev END)),2) END 
                                                                                                                                                                                    '--WHERE ACTION <> 2'

Exec sp_Executesql @SQL
SET @iterativeYear = @iterativeYear + 1
SET @iterativeColumn = @iterativeColumn + 1

END

END