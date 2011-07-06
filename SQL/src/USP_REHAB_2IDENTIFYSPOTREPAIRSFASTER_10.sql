USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_2IDENTIFYSPOTREPAIRSFASTER_10]    Script Date: 06/28/2011 16:25:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [ROSE\issacg].[USP_REHAB_2IDENTIFYSPOTREPAIRSFASTER_10] AS
BEGIN

------------------------------------------------------------------------------------------------
--Identify the temporary variables for this stored procedure
DECLARE @thisCompkey        int
DECLARE @iterativeYear      float
DECLARE @replaceYear        float
DECLARE @rValue             float
DECLARE @yearExponent       float
DECLARE @replaceSDev        float
DECLARE @interestValue      float
DECLARE @thisYear           float
DECLARE @ReplaceYear_Whole  float

----------------------------------------------------------------------------------------------
--The unit multiplier table is a way to speed up the query process.  Assuming that the end
--table 
CREATE TABLE #UnitMultiplierTable
(
	failure_yr int,
	std_dev int,
	unit_multiplier float
)

----------------------------------------------------------------------------------------------
--We wont be considering years prior to 1975 as failure years.  It is very very unlikely
--That any failure year could be assumed to be before 1975.
SET @iterativeYear = 1975

----------------------------------------------------------------------------------------------
--Fill the unit multiplier table with the appropriate values.  We won't be considering
--contributions following the year 2250.  This is about 50 years beyond any appreciable
--contribution due to standard deviations.
WHILE @iterativeYear <= 2250
BEGIN
	--------------------------------------------------------------------------------------------
	--We will assume that the range of possible standard deviations is 1 to 50.  I'm fairly
	--certain the standard deviation doesn't go much higher than 12, but just in case.
	SET @replaceSDev = 1
	WHILE @replaceSDev <= 50
	BEGIN
		----------------------------------------------------------------------------------------
		--Fill the unitMultiplier table with the base data.
		INSERT INTO #UnitMultiplierTable 
		SELECT	@iterativeYear as failure_yr, 
				@replaceSDev as std_dev, 
				0 as unit_multiplier
		SET @replaceSDev = @replaceSDev + 1
	END
	SET @iterativeYear = @iterativeYear + 1
END

----------------------------------------------------------------------------------------------
--Prepare the temporary variables with the base data
SET @ReplaceYear = 2040.00
SET @ReplaceYear_Whole = 2130
SET @ReplaceSDev = 12.00
SET @interestValue = 1.025
SET @thisYear = 2010.00
SET @iterativeYear = 2011

----------------------------------------------------------------------------------------------
--This is the loop that fills th
WHILE @iterativeYear <= 2250
BEGIN
	----------------------------------------------------------------------------------------------
	SET    @yearExponent = Power(@interestValue, @thisYear - @iterativeYear)
	----------------------------------------------------------------------------------------------
	UPDATE  #UnitMultiplierTable SET unit_multiplier = ISNULL(unit_multiplier, 0)+@yearExponent * [ROSE\issacg].gv(@iterativeYear,Failure_Yr ,Std_Dev,0)/std_dev
	---------------------------------------------------------------------------------------------- 
	SET @iterativeYear = @iterativeYear+1
END
	
----------------------------------------------------------------------------------------------
CREATE TABLE #CompkeyTable
(
	compkey int,
	numSegments float,
	numBroke float,
	numFixed float,
	Fail_tot float,
	Consequence_Failure float,
	Replacement_Cost float
)
----------------------------------------------------------------------------------------------
DROP TABLE  REHAB_SmallResultsTable
----------------------------------------------------------------------------------------------
CREATE TABLE  REHAB_SmallResultsTable
(
	compkey int,
	cutno int,
	fm int,
	[to] int,
	point_defect_score float,
	linear_defect_score float,
	total_defect_score float,
	Failure_Year int,
	Fail_Yr_Seg int,
	std_dev int,
	std_dev_Seg int,
	consequence_Failure int,
	replacement_cost int,
	R2010 float,
	R2150 float,
	B2010 float,
	B2150 float,
	B2010_Seg float,
	B2150_Seg float,
	R2010_Seg float,
	R2150_Seg float
)


--Create a new table of failure year, std dev, and unit multiple
--this table will assume that a repair costs one dollar,
--and then for every pipe, join with this table on
--failure year and standard deviation and multiply by the
--unit multiple.
----------------------------------------------------------------------------------------------
--problem with this solution is that I still need to consider the
--effect of deterioration.  First, find the group of std deviations
--that I need to care about:
SELECT std_dev from REHAB_SmallResultsTable group by std_dev order by std_dev
----------------------------------------------------------------------------------------------
--first make a list of compkeys that contain 4/5 graded segments
--hansen query
INSERT INTO #CompkeyTable 
	SELECT	COMPKEY, 
			0			AS numSegments, 
			Count(*)	AS numBroke, 
			0			AS numFixed, 
			0			AS Fail_tot, 
			MAX(Consequence_Failure)	AS Consequence_Failure, 
			MAX(Replacement_Cost)		AS Replacement_Cost 
	FROM  REHAB_RedundancyTable 
	WHERE RATING >= 1 and Total_Defect_Score >= 1000
	GROUP BY COMPKEY
----------------------------------------------------------------------------------------------
UPDATE #CompkeyTable 
SET #CompkeyTable.numSegments = A.numSegments 
FROM #CompkeyTable INNER JOIN 
(	
	SELECT	COMPKEY, 
			Count(*) AS numSegments 
	FROM  REHAB_RedundancyTable 
	GROUP BY COMPKEY
) AS A 
ON #CompkeyTable.compkey = A.Compkey

----------------------------------------------------------------------------------------------
UPDATE #CompkeyTable 
SET #CompkeyTable.numFixed = A.numFixed 
FROM #CompkeyTable INNER JOIN 
(	
	SELECT	COMPKEY, 
			Count(*) AS numFixed 
	FROM  REHAB_RedundancyTable		
	WHERE Material like '2_%' 
	GROUP BY COMPKEY
) AS A 
ON #CompkeyTable.compkey = A.Compkey
----------------------------------------------------------------------------------------------
UPDATE #CompkeyTable 
SET Fail_tot = theCount   
FROM	#CompkeyTable 
		INNER JOIN 
		(	
			SELECT	COMPKEY, 
					COUNT(*) AS theCOunt 
			FROM  REHAB_RedundancyTable 
			WHERE Total_Defect_Score >=1000 OR Material like '2_%' 
			GROUP BY COMPKEY
		) AS A 
ON #CompkeyTable.COMPKEY = A.COMPKEY

----------------------------------------------------------------------------------------------
UPDATE	REHAB_RedundancyTable 
SET		Fail_YR_Seg = Failure_Year, 
		Std_DEV_Seg = Std_Dev 
WHERE	Failure_Year <> 0 
		AND Std_Dev <>0
----------------------------------------------------------------------------------------------
--Update the standard deviation and failure years of pipes that have no hansen grade
UPDATE  REHAB_RedundancyTable 
SET		REHAB_RedundancyTable.Std_dev = STD, 
		Failure_Year = RUF + 2008 
FROM	REHAB_RedundancyTable AS tabA 
		INNER JOIN 
		(	
			SELECT	tabB.Compkey, 
					CASE WHEN Std_Dev_Calc < 1 THEN 1 ELSE Std_Dev_Calc END AS STD, 
					ISNULL(RUL_Final, 0) AS RUF
			FROM 
			(	
				SELECT	COMPKEY, 
						RUL_Final, 
						(RUL_Final*Std_dev_Coeff_RUL + ISNULL(Std_dev_Years_Insp,0) * ISNULL(Years_Since_Last_Inspect, 0))  AS Std_Dev_Calc
				FROM	REHAB_Tbl_RULmla_ac 
						INNER JOIN  
						REHAB_Rul_Std_dev 
						ON	RUL_Source_Flag = RUL_Source_ID
			)AS tabB 
		)AS tabC 
ON TabC.Compkey = tabA.Compkey AND (tabA.RATING IS NULL OR tabA.RATING = 0)
----------------------------------------------------------------------------------------------
UPDATE  REHAB_RedundancyTable 
SET		REHAB_RedundancyTable.RULife = RUF 
FROM	REHAB_RedundancyTable AS tabA 
		INNER JOIN 
		(
			SELECT	tabB.Compkey, 
					CASE WHEN Std_Dev_Calc < 1 THEN 1 ELSE Std_Dev_Calc END AS STD, 
					ISNULL(RUL_Final, 0) AS RUF
			FROM 
			(
				SELECT	COMPKEY, 
						RUL_Final, 
						(RUL_Final*Std_dev_Coeff_RUL + ISNULL(Std_dev_Years_Insp,0) * ISNULL(Years_Since_Last_Inspect, 0))  AS Std_Dev_Calc 
				FROM	REHAB_Tbl_RULmla_ac 
						INNER JOIN  
						REHAB_Rul_Std_dev 
						ON	RUL_Source_Flag = RUL_Source_ID
			)AS tabB 
		)AS tabC 
		ON TabC.Compkey = tabA.Compkey AND (tabA.RATING IS NULL OR tabA.RATING = 0)
----------------------------------------------------------------------------------------------
--Set failure year for 'jellybeans' that have score >=1000 and Fail_tot for the whole pipe < 0.1 AND numBroke for the whole pipe>= 1
--If a 'jellybean' meets these requirements, then that whole pipe must be replaced now.
UPDATE  REHAB_RedundancyTable 
SET		--Failure_Year = 2010, 
		--RULife = 0, 
		--Std_Dev = 12, 
		[ACTION] = 2 
FROM	REHAB_RedundancyTable 
		INNER JOIN 
		#CompkeyTable 
		ON 
		( 
			REHAB_RedundancyTable.Compkey = #CompkeyTable.Compkey
			AND 
			(
				#CompkeyTable.Fail_tot/#CompkeyTable.numSegments >= 0.1 
				AND 
				#CompkeyTable.numBroke > 1
			) 
			AND 
			( 
				REHAB_RedundancyTable.Insp_Curr = 1 
				OR  
				REHAB_RedundancyTable.Insp_Curr = 2
			) 
			AND	REHAB_RedundancyTable.RATING >=4
		)
----------------------------------------------------------------------------------------------
--If a 'jellybean' doesnt meet these requirements, then the pipe should be replaced in 30 years if there are spot repair that need to be done.
UPDATE	REHAB_RedundancyTable 
SET		--Failure_Year = 2040, 
		--RULife = 30, 
		--Std_Dev = 12
		[ACTION] = 3
FROM	REHAB_RedundancyTable 
		INNER JOIN 
		#CompkeyTable
		ON 
		( 
			REHAB_RedundancyTable.Compkey = #CompkeyTable.Compkey 
			AND 
			(
				(
					#CompkeyTable.Fail_tot/#CompkeyTable.numSegments < 0.1 
					AND 
					#CompkeyTable.numBroke > 1
				) 
				OR 
				(
					#CompkeyTable.Fail_tot/#CompkeyTable.numSegments >= 0.1 
					AND 
					#CompkeyTable.numBroke <= 1
				)
			) 
			AND 
			( 
				REHAB_RedundancyTable.Insp_Curr = 1 
				OR  
				REHAB_RedundancyTable.Insp_Curr = 2
			) 
			AND  
			REHAB_RedundancyTable.RATING >=4
		)
----------------------------------------------------------------------------------------------		
UPDATE	REHAB_RedundancyTable 
SET		[ACTION] = 4
FROM	REHAB_RedundancyTable 
		INNER JOIN 
		#CompkeyTable
		ON 
		( 
			REHAB_RedundancyTable.Compkey = #CompkeyTable.Compkey 
			AND 
			(
				( 
					#CompkeyTable.numBroke = 0
				) 
			)  
			AND  
			REHAB_RedundancyTable.RATING >=4
		)
		
----------------------------------------------------------------------------------------------
--If a pipe has an insp_curr of 3 (replaced after the last inspection) then the failure year of the pipe is 120 years from today.
UPDATE	REHAB_RedundancyTable 
SET		Failure_Year = 120 + 2010, 
		RULife = 120, 
		Std_Dev = 12 
where	insp_curr = 3
----------------------------------------------------------------------------------------------
UPDATE  REHAB_RedundancyTable 
SET		REHAB_RedundancyTable.RUL_Flag = RUL_Source_ID 
FROM	REHAB_RedundancyTable AS tabA 
		INNER JOIN 
		REHAB_Tbl_RULmla_ac  
		ON 
		tabA.COMPKEY = REHAB_Tbl_RULmla_ac.COMPKEY
--Get the PIpes that need spot repairs
--SELECT Compkey, numBroke, Replacement_Cost, numBroke*Replacement_Cost AS RepairCost FROM #CompkeyTable WHERE (numFixed + numBroke)/numSegments < 0.1 AND numBroke >= 1
--Get the costs of those spot repairs
--SELECT SUM(RepairCost) FROM (SELECT Compkey, numBroke, Replacement_Cost, numBroke*Replacement_Cost AS RepairCost FROM #CompkeyTable AS B WHERE (numFixed + numBroke)/numSegments < 0.1 AND numBroke >= 1  ) AS A

----------------------------------------------------------------------------------------------
--Pipes that have 4 or more failed laterals and are action 3 or action 4 need to be replaced now.
--These pipes will be called action 6 or 7.  
--ACTION 6 sanitary
/*UPDATE  REHAB_RedundancyTable SET /*Failure_Year = 2010, RULife = 0, Std_Dev = 12,*/ [ACTION] = 6
	FROM  
			(
				(
					[HANSEN].[IMSV7].[INSMNFR] AS A 
					INNER JOIN 
					[SANDBOX].[ROSE\issacg].REHAB_CONVERSION AS B 
					ON	A.INSPKEY = B.INSPKEY 
						AND A.RATING >= 3.9 
						AND RATINGKEY = 1010
				) 
				INNER JOIN 
				REHAB_RedundancyTable AS C 
				ON B.COMPKEY = C.COMPKEY
			)
			INNER JOIN 
			#CompkeyTable ON  
			C.Compkey = #CompkeyTable.Compkey 
			AND 
			(
				(
					#CompkeyTable.Fail_tot/#CompkeyTable.numSegments < 0.1 
					AND 
					#CompkeyTable.numBroke >= 1
				) 
				OR 
				(
					#CompkeyTable.Fail_tot/#CompkeyTable.numSegments >= 0.1 
					AND 
					#CompkeyTable.numBroke = 1
				)
			) 
			AND 
			(
				 C.Insp_Curr = 1 
				 OR  
				 C.Insp_Curr = 2
			) 
			AND  
			C.RATING >=4
	
----------------------------------------------------------------------------------------------	 
--Action 6 Storm
UPDATE  REHAB_RedundancyTable SET /*Failure_Year = 2010, RULife = 0, Std_Dev = 12,*/ [ACTION] = 6
FROM 
		(
			(
				[HANSEN].[IMSV7].[INSTMNFR] AS A 
				INNER JOIN 
				[SANDBOX].[ROSE\issacg].REHAB_CONVERSION AS B 
				ON	A.INSPKEY = B.INSPKEY 
					AND A.RATING >= 3.9 
					AND RATINGKEY = 1005
			) 
			INNER JOIN 
			REHAB_RedundancyTable AS C 
			ON B.COMPKEY = C.COMPKEY
		)
		INNER JOIN 
		#CompkeyTable 
		ON  C.Compkey = #CompkeyTable.Compkey 
		AND 
		(
			(
				#CompkeyTable.Fail_tot/#CompkeyTable.numSegments < 0.1 
				AND 
				#CompkeyTable.numBroke >= 1
			) 
			OR 
			(
				#CompkeyTable.Fail_tot/#CompkeyTable.numSegments >= 0.1 
				AND 
				#CompkeyTable.numBroke = 1
			)
		) 
		AND 
		(
			C.Insp_Curr = 1 
			OR  
			C.Insp_Curr = 2
		) 
		AND  
		C.RATING >=4
*/
/**********************************************/
UPDATE  REHAB_RedundancyTable SET MAT_FmTo = REHAB_RedundancyTable.Material FROM  REHAB_RedundancyTable INNER JOIN SANDBOX.GIS.REHAB10FTSEGS AS C ON  REHAB_RedundancyTable.MLinkID = C.MLinkID WHERE C.Material <>  REHAB_RedundancyTable.Material

--UPDATE segcount
UPDATE  REHAB_RedundancyTable SET seg_count = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCount FROM  REHAB_RedundancyTable GROUP BY COMPKEY) AS B ON  REHAB_RedundancyTable.COMPKEY = B.COMPKEY WHERE B.COMPKEY <> 0

--UPDATE fail_near
UPDATE  REHAB_RedundancyTable SET Fail_near = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCount FROM  REHAB_RedundancyTable WHERE Total_Defect_Score >= 1000 GROUP BY COMPKEY) AS A ON  REHAB_RedundancyTable.COMPKEY = A.COMPKEY

--UPDATE fail_prev
UPDATE  REHAB_RedundancyTable SET Fail_prev = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCount FROM  REHAB_RedundancyTable WHERE Material like '2_%' GROUP BY COMPKEY) AS A ON  REHAB_RedundancyTable.COMPKEY = A.COMPKEY

--UPDATE fail_TOT
UPDATE  REHAB_RedundancyTable SET Fail_tot = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCOunt FROM  REHAB_RedundancyTable WHERE Total_Defect_Score >=1000 OR Material like '2_%' GROUP BY COMPKEY) AS A ON  REHAB_RedundancyTable.COMPKEY = A.COMPKEY

--UPDATE fail_PCT
UPDATE  REHAB_RedundancyTable SET Fail_pct = CASE WHEN seg_count = 0 THEN 0 ELSE CAST(fail_tot AS FLOAT)/CAST(seg_count AS FLOAT)*100 END WHERE COMPKEY <> 0
/**************************************************/
----------------------------------------------------------------------------------------------
/*UPDATE  REHAB_RedundancyTable SET /*Failure_Year = 2010, RULife = 0, Std_Dev = 12,*/ [ACTION] = 7
FROM  
			([HANSEN].[IMSV7].[INSTMNFR] AS A INNER JOIN [SANDBOX].[ROSE\issacg].REHAB_CONVERSION AS B 
				ON A.INSPKEY = B.INSPKEY AND A.RATING >= 3.9 AND RATINGKEY = 1005
			) INNER JOIN REHAB_RedundancyTable AS C ON B.COMPKEY = C.COMPKEY
			AND

				 C.Fail_near = 0 
				AND
				(C.Insp_Curr = 1 OR  C.Insp_Curr = 2)
				AND
				C.RATING >=4

----------------------------------------------------------------------------------------------				
UPDATE  REHAB_RedundancyTable SET /*Failure_Year = 2010, RULife = 0, Std_Dev = 12,*/ [ACTION] = 7
	--SELECT C.COMPKEY, MAX(C.def_tot), MAX(C.fail_near), MAX(C.fail_tot)
	FROM  
			([HANSEN].[IMSV7].[INSMNFR] AS A INNER JOIN [SANDBOX].[ROSE\issacg].REHAB_CONVERSION AS B 
				ON A.INSPKEY = B.INSPKEY AND A.RATING >= 3.9 AND RATINGKEY = 1010
			) INNER JOIN REHAB_RedundancyTable AS C ON B.COMPKEY = C.COMPKEY
			AND

				 C.Fail_near = 0 
				AND
				 (C.Insp_Curr = 1 OR  C.Insp_Curr = 2)
				AND
				C.RATING >=4

		*/		
/**********************************************/
UPDATE  REHAB_RedundancyTable SET MAT_FmTo = REHAB_RedundancyTable.Material FROM  REHAB_RedundancyTable INNER JOIN SANDBOX.GIS.REHAB10FTSEGS AS C ON  REHAB_RedundancyTable.MLinkID = C.MLinkID WHERE C.Material <>  REHAB_RedundancyTable.Material

--UPDATE segcount
UPDATE  REHAB_RedundancyTable SET seg_count = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCount FROM  REHAB_RedundancyTable GROUP BY COMPKEY) AS B ON  REHAB_RedundancyTable.COMPKEY = B.COMPKEY WHERE B.COMPKEY <> 0

--UPDATE fail_near
UPDATE  REHAB_RedundancyTable SET Fail_near = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCount FROM  REHAB_RedundancyTable WHERE Total_Defect_Score >= 1000 GROUP BY COMPKEY) AS A ON  REHAB_RedundancyTable.COMPKEY = A.COMPKEY

--UPDATE fail_prev
UPDATE  REHAB_RedundancyTable SET Fail_prev = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCount FROM  REHAB_RedundancyTable WHERE Material like '2_%' GROUP BY COMPKEY) AS A ON  REHAB_RedundancyTable.COMPKEY = A.COMPKEY

--UPDATE fail_TOT
UPDATE  REHAB_RedundancyTable SET Fail_tot = theCount FROM  REHAB_RedundancyTable INNER JOIN (SELECT COMPKEY, COUNT(*) AS theCOunt FROM  REHAB_RedundancyTable WHERE Total_Defect_Score >=1000 OR Material like '2_%' GROUP BY COMPKEY) AS A ON  REHAB_RedundancyTable.COMPKEY = A.COMPKEY

--UPDATE fail_PCT
UPDATE  REHAB_RedundancyTable SET Fail_pct = CASE WHEN seg_count = 0 THEN 0 ELSE CAST(fail_tot AS FLOAT)/CAST(seg_count AS FLOAT)*100 END WHERE COMPKEY <> 0
/**************************************************/

----------------------------------------------------------------------------------------------
--Pipes that are between two action 2s, 6s, or 7s need to be replaced now.
--These pipes will be called action 8.
UPDATE	REHAB_RedundancyTableWhole 
Set		REHAB_RedundancyTableWhole.[Action] = REHAB_RedundancyTable.[Action]
FROM	REHAB_RedundancyTableWhole 
		INNER JOIN 
		REHAB_RedundancyTable 
		ON 
		REHAB_RedundancyTableWhole.COMPKEY = REHAB_RedundancyTable.COMPKEY

----------------------------------------------------------------------------------------------
/*UPDATE	REHAB_RedundancyTable 
SET		/*REHAB_RedundancyTable.Std_dev = 12, 
		Failure_Year = 2010, 
		RULife = 0 ,*/ 
		[ACTION] = 8
FROM 
	(
		(
			REHAB_RedundancyTable AS A 
			INNER JOIN 
			REHAB_RedundancyTableWhole AS B 
			ON A.COMPKEY = B.COMPKEY
		) 
		INNER JOIN 
		REHAB_RedundancyTableWhole AS C 
		ON B.UsNode = C.DsNode 
		AND 
		(
			C.[Action] = 2 
			OR 
			C.[Action] = 6 
			OR 
			C.[Action] = 7
		) 
		AND 
		(
			B.[Action] <> 2 
			AND 
			B.[Action] <> 6 
			AND 
			B.[Action] <> 7
		)
	) 
	INNER JOIN 
	REHAB_RedundancyTableWhole AS D 
	ON B.DsNode = D.UsNode
	AND 
	(
		D.[Action] = 2 
		OR 
		D.[Action] = 6 
		OR 
		D.[Action] = 7
	)

DELETE 
FROM	REHAB_SmallResultsTable*/
----------------------------------------------------------------------------------------------
--Do something that looks like the cost estimator to all of the PIpes
INSERT 
INTO	REHAB_SmallResultsTable 
		(
			compkey,
			cutno,
			fm,
			[to],
			point_defect_score,
			linear_defect_score,
			total_defect_score,
			Failure_Year,
			std_dev,
			consequence_Failure,
			replacement_cost,
			Std_Dev_Seg,
			Fail_YR_Seg
		)
SELECT	compkey,
		cutno,
		fm,
		[to],
		point_defect_score,
		linear_defect_score,
		total_defect_score,
		Failure_Year,
		std_dev,
		consequence_Failure,
		replacement_cost ,
		Std_Dev_Seg,
		Fail_YR_Seg 
FROM	REHAB_RedundancyTable


--update the failure Year on the Pipes with spot repairs to 40 years from now
--UPDATE  REHAB_SmallResultsTable SET Failure_Year = 2050 FROM  REHAB_SmallResultsTable INNER JOIN (SELECT Compkey, numBroke, Replacement_Cost, numBroke*Replacement_Cost AS RepairCost FROM #CompkeyTable AS B WHERE (numFixed + numBroke)/numSegments < 0.1 AND numBroke >= 1 ) AS A ON  REHAB_SmallResultsTable.Compkey = A.Compkey

----------------------------------------------------------------------------------------------
SET @iterativeYear = 1950.00
SET @ReplaceYear = 2040.00
SET @ReplaceYear_Whole = 2130
SET @ReplaceSDev = 12.00
SET @interestValue = 1.025
SET @thisYear = 2010.00
UPDATE  REHAB_SmallResultsTable SET B2010 = 0
UPDATE  REHAB_SmallResultsTable SET R2010 = 0
UPDATE  REHAB_SmallResultsTable SET B2150 = 0
UPDATE  REHAB_SmallResultsTable SET R2150 = 0

----------------------------------------------------------------------------------------------
--set the repair/mortality cost of segments to the area of the normal distribution
UPDATE  REHAB_SmallResultsTable 
SET		B2010 = Consequence_Failure * A 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		REHAB_NormalDistribution  
		ON Z = CASE WHEN ROUND((@thisYear-Failure_Year)/Std_Dev,2) < -3 THEN -4
                    WHEN ROUND((@thisYear-Failure_Year)/Std_Dev,2) >  3 THEN  4
                    ELSE ROUND((@thisYear-Failure_Year)/Std_Dev,2) 
               END  
----------------------------------------------------------------------------------------------
UPDATE  REHAB_SmallResultsTable 
SET		B2010_Seg = Consequence_Failure * A 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		REHAB_NormalDistribution  
		ON Z = CASE WHEN ROUND((@thisYear-Fail_YR_Seg)/Std_Dev_Seg,2) < -3 THEN -4
					WHEN ROUND((@thisYear-Fail_YR_Seg)/Std_Dev_Seg,2) >  3 THEN  4
                    ELSE ROUND((@thisYear-Fail_YR_Seg)/Std_Dev_Seg,2) 
               END  
WHERE	Std_Dev_Seg <> 0
----------------------------------------------------------------------------------------------                                                                                                                          
UPDATE  REHAB_SmallResultsTable 
SET		R2010 = Replacement_Cost + Consequence_Failure * A 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		REHAB_NormalDistribution  
		ON Z = CASE WHEN ROUND((@thisYear-@ReplaceYear_Whole)/@ReplaceSDev,2) < -3 THEN -4
                    WHEN ROUND((@thisYear-@ReplaceYear_Whole)/@ReplaceSDev,2) >  3 THEN  4
                    ELSE ROUND((@thisYear-@ReplaceYear_Whole)/@ReplaceSDev,2) 
			   END 

----------------------------------------------------------------------------------------------
UPDATE  REHAB_SmallResultsTable 
SET		R2010_Seg = Replacement_Cost + Consequence_Failure * A 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		REHAB_NormalDistribution  
		ON Z = CASE WHEN ROUND((@thisYear-@ReplaceYear)/@ReplaceSDev,2) < -3 THEN -4
                    WHEN ROUND((@thisYear-@ReplaceYear)/@ReplaceSDev,2) >  3 THEN  4
                    ELSE ROUND((@thisYear-@ReplaceYear)/@ReplaceSDev,2) 
               END 

----------------------------------------------------------------------------------------------
UPDATE  REHAB_SmallResultsTable 
SET		B2150 = Consequence_Failure * unit_multiplier 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		#UnitMultiplierTable 
		ON	REHAB_SmallResultsTable.Std_Dev = #UnitMultiplierTable.std_dev 
			AND 
			Failure_Year = failure_yr
----------------------------------------------------------------------------------------------
UPDATE  REHAB_SmallResultsTable 
SET		B2150_Seg = Consequence_Failure * unit_multiplier 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		#UnitMultiplierTable  
		ON	REHAB_SmallResultsTable.Std_Dev_seg = #UnitMultiplierTable.std_dev 
			AND 
			Fail_yr_seg = failure_yr
----------------------------------------------------------------------------------------------			
UPDATE	REHAB_SmallResultsTable 
SET		R2150 =	Consequence_Failure * unit_multiplier 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		#UnitMultiplierTable  
		ON	@ReplaceSDev = #UnitMultiplierTable.std_dev 
			AND 
			@ReplaceYear_Whole = failure_yr 
----------------------------------------------------------------------------------------------
UPDATE  REHAB_SmallResultsTable 
SET		R2150_Seg = Consequence_Failure * unit_multiplier 
FROM	REHAB_SmallResultsTable 
		INNER JOIN  
		#UnitMultiplierTable 
		ON	@ReplaceSDev = #UnitMultiplierTable.std_dev 
			AND 
			@ReplaceYear = failure_yr 
----------------------------------------------------------------------------------------------
DROP TABLE #CompkeyTable

END