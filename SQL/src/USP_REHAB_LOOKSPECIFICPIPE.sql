USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_LOOKSPECIFICPIPE]    Script Date: 06/28/2011 16:36:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [ROSE\issacg].[USP_REHAB_LOOKSPECIFICPIPE] AS
BEGIN

--Select * FROM CONVERSION WHERE COMPKEY = 144661

--EXEC sp_addlinkedserver   
--   @server='SIRTOBY', 
--   @srvproduct='SQL Server'
   --@provider='SQLOLEDB', 
   --@datasrc='SIRTOBY'

--EXEC sp_addlinkedsrvlogin @rmtsrvname = 'MODELING_DEV'
--, @useself = 'false'
----, @locallogin = 'ModelAdmin'
--, @rmtuser = 'MODELADMIN'
--, @rmtpassword = 'daW7horn'


--SELECT * INTO [MODELING_DEV].[MODELADMIN].[PIPEGRADES_20100426]
--FROM [SANDBOX].[GIS].[CONVERSION]
--SELECT * FROM HANSEN.IMSV7.COMPSTMN WHERE UNITID2 = 'ACM533'
/*SELECT SmallResultsTable.* FROM REHAB_PIPE_CALC INNER JOIN SmallResultsTable ON REHAB_PIPE_CALC.COMPKEY = SmallResultsTable.COMPKEY AND REHAB_PIPE_CALC.fm = SmallResultsTable.fm WHERE REHAB_PIPE_CALC.ACTION = 3 and REHAB_PIPE_CALC.DiamWidth <= 36 AND REHAB_PIPE_CALC.grade_h5 > 3 AND REHAB_PIPE_CALC.def_tot >=1000

SELECT * FROM REHAB_PIPE_CALC WHERE ACTION = 3 AND def_tot >=1000

SELECT SUM(B2010_Seg) AS theSum, 
		   36 AS PipeSize, 
            5 AS PipeGrade  FROM SmallResultsTable AS A INNER JOIN REHAB_PIPE_CALC AS B ON A.COMPKEY = B.COMPKEY AND A.fm = B.fm AND B.ACTION =3 AND B.DiamWidth <= 36 AND B.grade_h5 >3 AND B.def_tot >=1000
*/
/*SELECT * FROM RedundancyTable WHERE COMPKEY = 131779
SELECT * FROM REHAB_PIPE_CALC WHERE COMPKEY = 131779
SELECT * FROM RemainingYearsTable where MLINKID IN (SELECT MLINKID FROM REHAB_PIPE_CALC WHERE COMPKEY = 131779)*/
DELETE FROM JoesChartDataSums


INSERT INTO JoesChartDataSums SELECT Z, JobNo,
SUM(SpotRepair_2010),
SUM(	[2010]),
SUM(	[2011]),
SUM(	[2012]),
SUM(	[2013]),
SUM(	[2014]),
SUM(	[2015]),
SUM(	[2016]),
SUM(	[2017]),
SUM(	[2018]),
SUM(	[2019]),
SUM(	[2020]),
SUM(	[2021]),
SUM(	[2022]),
SUM(	[2023]),
SUM(	[2024]),
SUM(	[2025]),
SUM(	[2026]),
SUM(	[2027]),
SUM(	[2028]),
SUM(	[2029]),
SUM(	[2030]),
SUM(	[2031]),
SUM(	[2032]),
SUM(	[2033]),
SUM(	[2034]),
SUM(	[2035]),
SUM(	[2036]),
SUM(	[2037]),
SUM(	[2038]),
SUM(	[2039]),
SUM(	[2040]),
SUM(	[2041]),
SUM(	[2042]),
SUM(	[2043]),
SUM(	[2044]),
SUM(	[2045]),
SUM(	[2046]),
SUM(	[2047]),
SUM(	[2048]),
SUM(	[2049]),
SUM(	[2050]),
SUM(	[2051]),
SUM(	[2052]),
SUM(	[2053]),
SUM(	[2054]),
SUM(	[2055]),
SUM(	[2056]),
SUM(	[2057]),
SUM(	[2058]),
SUM(	[2059]),
SUM(	[2060])

FROM(SELECT (CASE WHEN PIPESIZE <= 36 THEN 36 ELSE 37 END) AS Z, JobNo, SpotRepair_2010, [2010],
[2011],
[2012],
[2013],
[2014],
[2015],
[2016],
[2017],
[2018],
[2019],
[2020],
[2021],
[2022],
[2023],
[2024],
[2025],
[2026],
[2027],
[2028],
[2029],
[2030],
[2031],
[2032],
[2033],
[2034],
[2035],
[2036],
[2037],
[2038],
[2039],
[2040],
[2041],
[2042],
[2043],
[2044],
[2045],
[2046],
[2047],
[2048],
[2049],
[2050],
[2051],
[2052],
[2053],
[2054],
[2055],
[2056],
[2057],
[2058],
[2059],
[2060]
FROM JoesChartData) AS TABz GROUP BY Z, JobNo

--SELECT SUM([2010]) FROM JoesChartData WHERE COMPKEY IN (SELECT COMPKEY FROM TheListOfPipes) AND [2010] <=10000

END
