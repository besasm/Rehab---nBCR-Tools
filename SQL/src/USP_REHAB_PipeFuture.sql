USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_PipeFuture]    Script Date: 06/28/2011 16:36:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [ROSE\issacg].[USP_REHAB_PipeFuture]  --(@Compkey int)
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
DELETE FROM REHAB_PipeFuture
--
INSERT INTO REHAB_PipeFuture SELECT COMPKEY, MLinkID, [ACTION], 0, ReplaceCost AS CostToReplaceASegment, Fail_Near As CountOfSegmentsToReplace, Std_dev_seg AS SegmentStdDev, Fail_Yr_seg  AS SegmentReplaceYear, ReplaceCost AS SegmentReplaceCost, cof, DiamWidth AS PipeSize, Grade_H5 AS PIPEGRADE,
0,
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
,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0
,0,0,0,0,0,0,0,0,0,0
FROM [SANDBOX].[GIS].[REHAB10FTSEGS] WHERE MLINKID >= 40000000 
AND REMARKS = 'BES' 
AND ReplaceCost <> 0 
AND Std_dev_seg <> 0
AND Fail_yr_seg <> 0
and replaceCost <> 0
and cof <>0-- AND COMPKEY =@Compkey 

SET @ReplaceYear = 2040.00
SET @ReplaceYear_Whole = 2130
SET @ReplaceSDev = 12.00
SET @thisYear = 2010.00

--UPDATE REHAB_PipeFuture SET [2010] = cof * [ROSE\issacg].gv(@thisYear,SegmentReplaceYear ,SegmentStdDev,1)

DECLARE @columnName			nchar(6)
DECLARE @interestValue      float

SET @thisYear = 2010.00
SET @iterativeYear = 2011
SET @iterativeColumn = 14

WHILE @iterativeYear <= 2120
BEGIN
--
Select @columnName = Column_Name from Information_Schema.columns 
where Ordinal_position = @iterativeColumn and Table_Name = 'REHAB_PipeFuture'
--
SET    @yearExponent = Power(@interestValue, @thisYear - @iterativeYear)
Set @SQL  = 'UPDATE REHAB_PipeFuture SET ['+@columnName+'] = cof * [ROSE\issacg].gv('+convert(varchar(10), convert(numeric(12,2),@iterativeYear))+',SegmentReplaceYear ,SegmentStdDev,1)'

Exec sp_Executesql @SQL
SET @iterativeYear = @iterativeYear + 1
SET @iterativeColumn = @iterativeColumn + 1
--
END

SELECT
SUM([2010]) AS [2010]
,SUM([2011]) AS [2011]
,SUM([2012]) AS [2012]
,SUM([2013]) AS [2013]
,SUM([2014]) AS [2014]
,SUM([2015]) AS [2015]
,SUM([2016]) AS [2016]
,SUM([2017]) AS [2017]
,SUM([2018]) AS [2018]
,SUM([2019]) AS [2019]
,SUM([2020]) AS [2020]
,SUM([2021]) AS [2021]
,SUM([2022]) AS [2022]
,SUM([2023]) AS [2023]
,SUM([2024]) AS [2024]
,SUM([2025]) AS [2025]
,SUM([2026]) AS [2026]
,SUM([2027]) AS [2027]
,SUM([2028]) AS [2028]
,SUM([2029]) AS [2029]
,SUM([2030]) AS [2030]
,SUM([2031]) AS [2031]
,SUM([2032]) AS [2032]
,SUM([2033]) AS [2033]
,SUM([2034]) AS [2034]
,SUM([2035]) AS [2035]
,SUM([2036]) AS [2036]
,SUM([2037]) AS [2037]
,SUM([2038]) AS [2038]
,SUM([2039]) AS [2039]
,SUM([2040]) AS [2040]
,SUM([2041]) AS [2041]
,SUM([2042]) AS [2042]
,SUM([2043]) AS [2043]
,SUM([2044]) AS [2044]
,SUM([2045]) AS [2045]
,SUM([2046]) AS [2046]
,SUM([2047]) AS [2047]
,SUM([2048]) AS [2048]
,SUM([2049]) AS [2049]
,SUM([2050]) AS [2050]
,SUM([2051]) AS [2051]
,SUM([2052]) AS [2052]
,SUM([2053]) AS [2053]
,SUM([2054]) AS [2054]
,SUM([2055]) AS [2055]
,SUM([2056]) AS [2056]
,SUM([2057]) AS [2057]
,SUM([2058]) AS [2058]
,SUM([2059]) AS [2059]
,SUM([2060]) AS [2060]
,SUM([2061]) AS [2061]
,SUM([2062]) AS [2062]
,SUM([2063]) AS [2063]
,SUM([2064]) AS [2064]
,SUM([2065]) AS [2065]
,SUM([2066]) AS [2066]
,SUM([2067]) AS [2067]
,SUM([2068]) AS [2068]
,SUM([2069]) AS [2069]
,SUM([2070]) AS [2070]
,SUM([2071]) AS [2071]
,SUM([2072]) AS [2072]
,SUM([2073]) AS [2073]
,SUM([2074]) AS [2074]
,SUM([2075]) AS [2075]
,SUM([2076]) AS [2076]
,SUM([2077]) AS [2077]
,SUM([2078]) AS [2078]
,SUM([2079]) AS [2079]
,SUM([2080]) AS [2080]
,SUM([2081]) AS [2081]
,SUM([2082]) AS [2082]
,SUM([2083]) AS [2083]
,SUM([2084]) AS [2084]
,SUM([2085]) AS [2085]
,SUM([2086]) AS [2086]
,SUM([2087]) AS [2087]
,SUM([2088]) AS [2088]
,SUM([2089]) AS [2089]
,SUM([2090]) AS [2090]
,SUM([2091]) AS [2091]
,SUM([2092]) AS [2092]
,SUM([2093]) AS [2093]
,SUM([2094]) AS [2094]
,SUM([2095]) AS [2095]
,SUM([2096]) AS [2096]
,SUM([2097]) AS [2097]
,SUM([2098]) AS [2098]
,SUM([2099]) AS [2099]
,SUM([2100]) AS [2100]
,SUM([2101]) AS [2101]
,SUM([2102]) AS [2102]
,SUM([2103]) AS [2103]
,SUM([2104]) AS [2104]
,SUM([2105]) AS [2105]
,SUM([2106]) AS [2106]
,SUM([2107]) AS [2107]
,SUM([2108]) AS [2108]
,SUM([2109]) AS [2109]
,SUM([2110]) AS [2110]
,SUM([2111]) AS [2111]
,SUM([2112]) AS [2112]
,SUM([2113]) AS [2113]
,SUM([2114]) AS [2114]
,SUM([2115]) AS [2115]
,SUM([2116]) AS [2116]
,SUM([2117]) AS [2117]
,SUM([2118]) AS [2118]
,SUM([2119]) AS [2119]
,SUM([2120]) AS [2120]
FROM [SANDBOX].[ROSE\issacg].[REHAB_PipeFuture]
GROUP BY COMPKEY

END