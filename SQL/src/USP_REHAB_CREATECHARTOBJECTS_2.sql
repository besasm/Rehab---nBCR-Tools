USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_CREATECHARTOBJECTS_2]    Script Date: 06/28/2011 16:32:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [ROSE\issacg].[USP_REHAB_CREATECHARTOBJECTS_2] AS
BEGIN
DELETE FROM REHAB_JoesChartDataSums


INSERT INTO REHAB_JoesChartDataSums SELECT Z, JobNo,
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
FROM REHAB_JoesChartData) AS TABz GROUP BY Z, JobNo


END
