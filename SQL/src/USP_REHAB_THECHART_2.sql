USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_THECHART_2]    Script Date: 06/28/2011 16:37:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [ROSE\issacg].[USP_REHAB_THECHART_2] AS
BEGIN

DECLARE @thisCompkey        int
DECLARE @iterativeYear      float
DECLARE @replaceYear        float
DECLARE @rValue             float
DECLARE @yearExponent       float
DECLARE @replaceSDev        float
DECLARE @thisYear			float
DECLARE @interestValue		float


DECLARE @ReplaceYear_Whole  float
DECLARE @iterativeColumn	int
--Declare @columnName			nchar(4)
DECLARE @SQL				nchar(4000)

DELETE FROM REHAB_JoesChartData
DELETE FROM REHAB_JoesChartDataCheck

CREATE TABLE #UnitMultiplierTable
(
	failure_yr int,
	std_dev int,
	unit_multiplier float
)

SET @iterativeYear = 1975
WHILE @iterativeYear <= 2250
BEGIN
	SET @replaceSDev = 1
	WHILE @replaceSDev <= 50
	BEGIN
		INSERT INTO #UnitMultiplierTable SELECT @iterativeYear as failure_yr, @replaceSDev as std_dev, 0 as unit_multiplier
		SET @replaceSDev = @replaceSDev + 1
	END
	SET @iterativeYear = @iterativeYear + 1
END

SET @ReplaceYear = 2040.00
SET @ReplaceYear_Whole = 2130
SET @ReplaceSDev = 12.00
SET @interestValue = 1.025
SET @thisYear = 2010.00
SET @iterativeYear = 2011
WHILE @iterativeYear <= 2250
BEGIN
	SET    @yearExponent = Power(@interestValue, @thisYear - @iterativeYear)
	UPDATE  #UnitMultiplierTable SET unit_multiplier = ISNULL(unit_multiplier, 0)+@yearExponent * [ROSE\issacg].gv(@iterativeYear,Failure_Yr ,Std_Dev,0)/std_dev 
	SET @iterativeYear = @iterativeYear+1
END


INSERT INTO REHAB_JoesChartData SELECT COMPKEY, MLinkID, ACTION, 0, (ReplaceCost/Seg_Count) AS CostToReplaceASegment, (CASE WHEN ACTION = 3 THEN Fail_Near ELSE 0 END) AS CountOfSegmentsToReplace, (CASE WHEN ACTION = 3 then 12 ELSE Std_dev END) AS WholePipeStdDev, /*(CASE WHEN ACTION = 3 THEN (CASE WHEN Fail_Yr < 2050 THEN Fail_Yr ELSE 2050 END) ELSE Fail_Yr END)*/(CASE WHEN ACTION = 3 THEN 2040 ELSE Fail_Yr END) AS WholePipeReplaceYear, ReplaceCost AS WholePipeReplaceCost, DiamWidth AS PipeSize, Grade_H5 AS PIPEGRADE,
(ReplaceCost/Seg_Count)*(CASE WHEN ACTION = 3 THEN Fail_Near ELSE 0 END),
0,0,0,0,  0,0,0,0,  0,0,0,0,  
0,0,0,0,  0,0,0,0,  0,0,0,0,
0,0,0,0,  0,0,0,0,  0,0,0,0,  
0,0,0,0,  0,0,0,0,  0,0,0,0,
0,0,0
FROM REHAB_PIPE_CALC WHERE MLINKID < 40000000 AND COMPKEY <> 0 AND REMARKS = 'BES' AND COMPKEY NOT IN 
--dont let any whole pipes in that have more than one record based on compkey
(SELECT COMPKEY FROM (SELECT COMPKEY, COUNT(*) AS THECOUNT FROM REHAB_PIPE_CALC WHERE MLINKID < 40000000 AND COMPKEY <> 0 GROUP BY COMPKEY ) AS A WHERE THECOUNT > 1)

UPDATE REHAB_JoesChartData SET JobNo = 1    WHERE ACTION = 3
UPDATE REHAB_JoesChartData SET JobNo = 8400 WHERE COMPKEY IN (SELECT COMPKEY FROM REHAB_tblProject8400)
UPDATE REHAB_JoesChartData SET JobNo = 4863 WHERE COMPKEY IN (SELECT COMPKEY FROM REHAB_tblProject4863)

SET @ReplaceYear = 2040.00
SET @ReplaceYear_Whole = 2130
SET @ReplaceSDev = 12.00
SET @thisYear = 2010.00


UPDATE REHAB_JoesChartData SET [2010] = WholePipeReplaceCost * A FROM REHAB_JoesChartData INNER JOIN REHAB_NormalDistribution  ON Z = CASE WHEN ROUND((@thisYear-WholePipeReplaceYear)/WholePipeStdDev,2) < -3 THEN -4
                                                                                                                               WHEN ROUND((@thisYear-WholePipeReplaceYear)/WholePipeStdDev,2) >  3 THEN  4
                                                                                                                               ELSE ROUND((@thisYear-WholePipeReplaceYear)/WholePipeStdDev,2) END



DECLARE @columnName			nchar(6)

SET @thisYear = 2010.00
SET @interestValue = 1.025
SET @iterativeYear = 2011
SET @iterativeColumn = 13

WHILE @iterativeYear <= 2060
BEGIN

Select @columnName = Column_Name from Information_Schema.columns 
where Ordinal_position = @iterativeColumn and Table_Name = 'REHAB_JoesChartData'


SET    @yearExponent = Power(@interestValue, @thisYear - @iterativeYear)
Set @SQL  = '
UPDATE REHAB_JoesChartData SET ['+@columnName+'] = ' + convert(varchar(10), convert(numeric(12,2), @yearExponent))+ ' * WholePipeReplaceCost * (ISNULL(P,0)/WholePipeStdDev) FROM REHAB_JoesChartData INNER JOIN REHAB_NormalDistribution  ON Z = CASE WHEN ROUND(('+convert(varchar(10), convert(numeric(12,2),@iterativeYear))+'-convert(numeric(12,2),WholePipeReplaceYear))/convert(numeric(12,2),WholePipeStdDev),2) < -3 THEN -4
                                                                                                                                                                                    WHEN ROUND(('+convert(varchar(10), convert(numeric(12,2),@iterativeYear))+'-convert(numeric(12,2),WholePipeReplaceYear))/convert(numeric(12,2),WholePipeStdDev),2) >  3 THEN  4
                                                                                                                                                                                    ELSE ROUND(('+convert(varchar(10), convert(numeric(12,2),@iterativeYear))+'-convert(numeric(12,2),WholePipeReplaceYear))/convert(numeric(12,2),WholePipeStdDev),2) END '

Exec sp_Executesql @SQL
SET @iterativeYear = @iterativeYear + 1
SET @iterativeColumn = @iterativeColumn + 1

END

END