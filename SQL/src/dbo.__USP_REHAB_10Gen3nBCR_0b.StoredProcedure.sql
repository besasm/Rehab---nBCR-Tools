USE [REHAB]
GO
/****** Object:  StoredProcedure [dbo].[__USP_REHAB_10Gen3nBCR_0b]    Script Date: 02/12/2016 09:07:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[__USP_REHAB_10Gen3nBCR_0b] 
AS
BEGIN
  --Goal for this particular procedure is to get the nBCR for the various solutions
  --using the failure year as the current year.  This will let us know what BPW
  --solution we should be using right now.  ASMFailureAction will be the column that stores this information.
  --Make sure that this becomes input for the solutions that we are using, especially for the
  --(BPW-APW)/cost solution.
  
  --Different approaches:
  --Run this procedure several times, starting with the current year, then moving forward
  --until we hit the final window year (currently 20 years right now).  This seems goofy, isn't there some
  --other way to approach this particular thing?  I don't know. 
  
  --Maybe fill a table with only the pipes that are predicted to fail in a year (@thisYear), and then 
  --do a loop, incrementing @thisYear by one each time (for(@thisYear = minFailYear; @thisYear < @realCurrentYear + @actionWindow; @thisYear++))
  --Where @realCurrentYear = 2016 and @actionWindow = 20
  
  --The only table that gets modified in this query is REHAB_Branches, so I think I can make a proxy for REHAB_Branches, and another table that 
  --holds the failAction and maybe the failBPW?
  --Well I think the failBPW would be calculated for
  
  --Still need to account for the fact that there are plenty of pipes that have failure years less than the current failure year.
  --In that case, I can just insert those failure years into a temp table and tdo a foreach
  SET NOCOUNT ON;
  
  DECLARE @thisYear int = YEAR(GETDATE())
  DECLARE @CurrentYear int = YEAR(GETDATE())
  DECLARE @SpotRotationFrequency int = 20
  DECLARE @EmergencyFactor float = 1.4
  DECLARE @StdDevWholePipeAt120Years int = 12
  DECLARE @MaxStdDev int = 12
  DECLARE @StdDevNewLiner int = 6
  DECLARE @RULNewWholePipe int = 120
  DECLARE @RULNewLiner int = 60
  DECLARE @LineAtYearNoSpots int = 20
  DECLARE @LineAtYearSpots int = 30
  DECLARE @StdDevNewSpot int = 4
  DECLARE @RULNewSpot int = 30
  DECLARE @HoursPerDay float = 8.0
  DECLARE @ActionWindow INT = 20
  
  DECLARE @unacceptableSurchargeFootage FLOAT = 1.0
  DECLARE @unacceptableOvallingFraction FLOAT = 0.1
  DECLARE @unacceptableSagFraction FLOAT = 0.1
  
  --Create a table that is a list of failure years all the way up until 20 years from now
  --The table starts at the current year
  --All pipes that have failure years before the current year are calculated as though they fail this year (current year)
  --Maybe this table doesn't need to exist?  Just go through all 20 years anyway?
  --
  CREATE TABLE #FailureYears
  (
    ID  INT IDENTITY (1,1),
    FailureYear INT
  )
  
  INSERT INTO #FailureYears (FailureYear)
  SELECT Fail_Yr
  FROM   REHAB.GIS.REHAB_Segments
  WHERE  Fail_Yr <= @CurrentYear + @ActionWindow
         AND
         Fail_Yr >= @CurrentYear
         AND
         cutno = 0
  GROUP BY Fail_Yr
  ORDER BY Fail_yr
  
CREATE TABLE #Branches(
	[COMPKEY] [int] NULL,
	[ASM_Gen3Solution] [nvarchar](32) NULL,
	[ASM_Gen3SolutionnBCR] [float] NULL,
	[nBCR_OC_OC] [float] NULL,
	[nBCR_OC_CIPP] [float] NULL,
	[nBCR_OC_SP] [float] NULL,
	[nBCR_CIPP_OC] [float] NULL,
	[nBCR_CIPP_CIPP] [float] NULL,
	[nBCR_CIPP_SP] [float] NULL,
	[nBCR_SP_OC] [float] NULL,
	[nBCR_SP_CIPP] [float] NULL,
	[nBCR_SP_SP] [float] NULL,
	[InitialFailYear] [int] NULL,
	[LineAtYear] [int] NULL,
	[LineAtYearAPW] [int] NULL,
	[std_dev] [int] NULL,
	[ReplaceCost] [float] NULL,
	[SpotCost] [float] NULL,
	[MaxSegmentCOFwithoutReplacement] [float] NULL,
	[LineCostNoSpots] [float] NULL,
	[SpotCost01] [float] NULL,
	[SpotCost02] [float] NULL,
	[SpotCostFail01] [float] NULL,
	[SpotCostFail02] [float] NULL,
	[BPWOCfail01] [float] NULL,
	[BPWOCfail02] [float] NULL,
	[BPWCIPPfail01] [float] NULL,
	[BPWCIPPfail02] [float] NULL,
	[BPWCIPPfail03] [float] NULL,
	[BPWSPfail01] [float] NULL,
	[BPWSPfail02] [float] NULL,
	[BPWSPfail03] [float] NULL,
	[BPWSPfail04] [float] NULL,
	[APWOC01] [float] NULL,
	[APWOC02] [float] NULL,
	[APWCIPP01] [float] NULL,
	[APWCIPP02] [float] NULL,
	[APWCIPP03] [float] NULL,
	[APWSP01] [float] NULL,
	[APWSP02] [float] NULL,
	[APWSP03] [float] NULL,
	[APWSP04] [float] NULL,
	[BPWOC] [float] NULL,
	[APWOC] [float] NULL,
	[BPWSP] [float] NULL,
	[APWSP] [float] NULL,
	[BPWCIPP] [float] NULL,
	[APWCIPP] [float] NULL,
	[Problems] [nvarchar](512) NULL
)


  /*TRUNCATE TABLE REHAB.GIS.REHAB_Branches
  
  INSERT INTO REHAB.GIS.REHAB_Branches(COMPKEY, [InitialFailYear], std_dev, ReplaceCost, SpotCost, LineCostNoSpots)
  SELECT  compkey, fail_yr, std_dev, replaceCost, SpotCost, LineCostNoSegsNoLats
  FROM    REHAB.GIS.REHAB_Segments AS A
  WHERE   cutno = 0*/
  
WHILE (@thisYear <= @CurrentYear + @ActionWindow)
BEGIN
  PRINT @thisYear
  CREATE TABLE #Costs
  (
    Compkey INT,
    NonMobCap FLOAT,
    Rate FLOAT,
    BaseTime FLOAT,
    MobTime FLOAT
  )
  
  TRUNCATE TABLE #Branches
  
  IF (@thisYear = @CurrentYear)
  BEGIN
    INSERT INTO #Branches(COMPKEY, [InitialFailYear], std_dev, ReplaceCost, SpotCost, LineCostNoSpots)
    SELECT  compkey, fail_yr, std_dev, replaceCost, SpotCost, LineCostNoSegsNoLats
    FROM    REHAB.GIS.REHAB_Segments AS A
    WHERE   cutno = 0
            AND
            fail_yr <= @thisYear
  END
  IF (@thisYear != @CurrentYear)
  BEGIN
    INSERT INTO #Branches(COMPKEY, [InitialFailYear], std_dev, ReplaceCost, SpotCost, LineCostNoSpots)
    SELECT  compkey, fail_yr, std_dev, replaceCost, SpotCost, LineCostNoSegsNoLats
    FROM    REHAB.GIS.REHAB_Segments AS A
    WHERE   cutno = 0
            AND
            fail_yr = @thisYear
  END
  
  
  --This probably could be average instead of max.  This might need some work after cost estimator is finished
  UPDATE  #Branches
  SET     MaxSegmentCOFwithoutReplacement = B.maxSegCofWithoutReplacement
  FROM    #Branches AS A
          INNER JOIN
          (  
            SELECT  compkey, MAX(COF-@EmergencyFactor*ReplaceCost) AS maxSegCofWithoutReplacement
            FROM    REHAB.GIS.REHAB_Segments AS Z
            WHERE   cutno > 0
            GROUP BY COMPKEY
          ) AS B
          ON  A.COMPKEY = B.compkey
        
  UPDATE  #Branches
  SET     SpotCost01 = ISNULL(B.TotalFirstSpotRepairs,0)
  FROM    #Branches AS A
          INNER JOIN
          (  
            SELECT  Z.compkey, SUM([CapitalNonMobilization]) + MAX([CapitalMobilizationRate])*(SUM(BaseTime) + MAX([MobilizationTime]))/@HoursPerDay AS TotalFirstSpotRepairs
            FROM    REHAB.GIS.REHAB_Segments AS Z
                    INNER JOIN
                    [COSTEST_CapitalCostsMobilizationRatesAndTimes] AS ZZ1
                    ON  Z.ID = ZZ1.ID
                        AND
						ZZ1.[type] = 'Spot'
            WHERE   Z.cutno > 0
                    AND
                    Z.fail_yr_seg <= @thisYear + @SpotRotationFrequency
                    AND
                    (
                      Z.def_tot >= 1000
                      OR
                      [action] = 3
                    )
            GROUP BY Z.COMPKEY
          ) AS B
          ON  A.COMPKEY = B.compkey
          
  UPDATE  #Branches
  SET     SpotCost02 = (ISNULL(B.TotalSecondSpotRepairs,0))
  FROM    #Branches AS A
          INNER JOIN
          (  
            SELECT  Z.compkey, ((SUM([CapitalNonMobilization]) + MAX([CapitalMobilizationRate])*(SUM(BaseTime) + MAX([MobilizationTime]))/@HoursPerDay)) AS TotalSecondSpotRepairs
            FROM    REHAB.GIS.REHAB_Segments AS Z
                    INNER JOIN
                    [COSTEST_CapitalCostsMobilizationRatesAndTimes] AS ZZ1
                    ON  Z.ID = ZZ1.ID
                        AND
						ZZ1.[type] = 'Spot'
            WHERE   cutno > 0
                    AND
                    --fail_yr_seg <= @thisYear + 2*@SpotRotationFrequency
                    --AND
                    fail_yr_seg > @thisYear + @SpotRotationFrequency
                    AND
                    (
                      Z.def_tot >= 1000
                      OR
                      [action] = 3
                    )
            GROUP BY Z.COMPKEY
          ) AS B
          ON  A.COMPKEY = B.compkey
  
                      
  --Cost to replace all of the near failing spots after the initial failure year     
  UPDATE  #Branches
  SET     SpotCostFail01 = ISNULL(B.TotalFirstSpotRepairs,0) 
  FROM    #Branches AS A
          INNER JOIN
          (  
            SELECT  Z.compkey, (SUM([CapitalNonMobilization]) + MAX([CapitalMobilizationRate])*(SUM(BaseTime) + MAX([MobilizationTime]))/@HoursPerDay) AS TotalFirstSpotRepairs
            FROM    REHAB.GIS.REHAB_Segments AS Z
                    INNER JOIN
                    [COSTEST_CapitalCostsMobilizationRatesAndTimes] AS ZZ1
                    ON  Z.ID = ZZ1.ID
                        AND
						ZZ1.[type] = 'Spot'
                    INNER JOIN
                    #Branches AS X
                    ON  Z.compkey = X.compkey 
            WHERE   Z.cutno > 0
                    AND
                    Z.fail_yr_seg <= X.[InitialFailYear] + @SpotRotationFrequency
                    AND
                    (
                      Z.def_tot >= 1000
                      OR
                      [action] = 3
                    )
            GROUP BY Z.compkey
          ) AS B
          ON  A.COMPKEY = B.compkey
  
          
  UPDATE  #Branches
  SET     SpotCostFail02 = ISNULL(B.TotalSecondSpotRepairs,0)
  FROM    #Branches AS A
          INNER JOIN
          (  
            SELECT  Z.compkey, @EmergencyFactor*SUM([CapitalNonMobilization]) + MAX([CapitalMobilizationRate])*(SUM(BaseTime) + MAX([MobilizationTime]))/@HoursPerDay AS TotalSecondSpotRepairs
            FROM    REHAB.GIS.REHAB_Segments AS Z
                    INNER JOIN
                    [COSTEST_CapitalCostsMobilizationRatesAndTimes] AS ZZ1
                    ON  Z.ID = ZZ1.ID
                        AND
						ZZ1.[type] = 'Spot'
                    INNER JOIN
                    #Branches AS X
                    ON  Z.compkey = X.compkey 
            WHERE   Z.cutno > 0
                    AND
                    --Z.fail_yr_seg <= X.[InitialFailYear] + 2*@SpotRotationFrequency
                    --AND
                    Z.fail_yr_seg > X.[InitialFailYear] + @SpotRotationFrequency
                    AND
                    (
                      Z.def_tot >= 1000
                      OR
                      [action] = 3
                    )
            GROUP BY Z.compkey
          ) AS B
          ON  A.COMPKEY = B.compkey       
          
          
  UPDATE  #Branches
  SET     BPWOCFail01 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  A.std_dev = B.std_dev
              AND 
              A.InitialFailYear = B.failure_yr 
  
  UPDATE  #Branches
  SET     BPWOCFail02 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @MaxStdDev = B.std_dev
              AND 
              A.InitialFailYear + @RULNewWholePipe= B.failure_yr 
  
  
  --On a reactive lining job, all bad spots are replaced
  
    
  TRUNCATE TABLE #Costs
  INSERT INTO #Costs ( Compkey, NonMobCap, Rate, BaseTime, MobTime )
  SELECT  Z.compkey, 
						SUM([CapitalNonMobilization]) AS SpotNonMobCap,
						MAX([CapitalMobilizationRate]) AS SpotRate,
						SUM(BaseTime) AS SpotBaseTime,
						MAX([MobilizationTime]) AS SpotMobTime
				FROM    REHAB.GIS.REHAB_Segments AS Z
						INNER JOIN
						[COSTEST_CapitalCostsMobilizationRatesAndTimes] AS ZZ1
						ON  Z.ID = ZZ1.ID
						    AND
						    ZZ1.[type] = 'Spot'
						INNER JOIN
						#Branches AS X
						ON  Z.compkey = X.compkey 
				WHERE   Z.cutno > 0
						AND
						(
						  [action] = 3
						  OR
						  (
						    Z.def_tot >= 1000
						    AND
						    Z.fail_yr_seg <= X.[InitialFailYear] + @SpotRotationFrequency
						  )
						)
				GROUP BY Z.compkey
				
  UPDATE  #Branches
  SET     BPWCIPPfail01 = (TotalSpotLineCost*@EmergencyFactor+C.MaxSegmentCOFwithoutReplacement)*ISNULL(B.unit_multiplier,0) 
  FROM    (
            SELECT Table1.COMPKEY, 
                   (ISNULL(NonMobCap,0) + LineNonMobCap) 
                   + (CASE WHEN ISNULL(Rate,0) > ISNULL(LineRate,0) THEN ISNULL(Rate,0) ELSE ISNULL(LineRate,0) END)
                   * (
                       CASE WHEN ISNULL(MobTime,0) > ISNULL(LineMobTime,0) THEN ISNULL(MobTime,0) ELSE ISNULL(LineMobTime,0) END
                       +
                       (ISNULL(BaseTime,0) + LineBaseTime)
                     )/@HoursPerDay AS TotalSpotLineCost
            FROM #Costs AS Table1
            INNER JOIN
            (
              SELECT  Compkey,
                      [CapitalNonMobilization] AS LineNonMobCap,
				      [CapitalMobilizationRate] AS LineRate,
					  BaseTime AS LineBaseTime,
					  [MobilizationTime] AS LineMobTime
              FROM    [COSTEST_CapitalCostsMobilizationRatesAndTimes]
              WHERE   [type] = 'Line'
                      AND 
                      ID < 40000000
            ) AS Table2
            ON Table1.Compkey = Table2.Compkey
          ) AS A
          INNER JOIN  
          #Branches AS C
          ON  A.Compkey = C.Compkey
          INNER JOIN
          REHAB_UnitMultiplierTable AS B
          ON  C.std_dev = B.std_dev
              AND 
              C.InitialFailYear = B.failure_yr
               
  UPDATE  #Branches
  SET     BPWCIPPfail02 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @StdDevNewLiner = B.std_dev
              AND 
              A.InitialFailYear + @RULNewLiner = B.failure_yr
              
  UPDATE  #Branches
  SET     BPWCIPPfail03 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @MaxStdDev = B.std_dev
              AND 
              A.InitialFailYear + @RULNewLiner +@RULNewWholePipe = B.failure_yr
  
  UPDATE  #Branches
  SET     BPWSPfail01 = (A.SpotCostFail01*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)*ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  A.std_dev = B.std_dev
              AND 
              A.InitialFailYear = B.failure_yr
  
  UPDATE  #Branches
  SET     LineAtYear = @LineAtYearSpots
  FROM    #Branches AS A
  WHERE   A.SpotCostFail02 > 0
  
  UPDATE  #Branches
  SET     LineAtYear = @LineAtYearNoSpots
  FROM    #Branches AS A
  WHERE   ISNULL(A.SpotCostFail02,0) = 0
  
  
  TRUNCATE TABLE #Costs
  INSERT INTO #Costs ( Compkey, NonMobCap, Rate, BaseTime, MobTime )
  SELECT  X.COMPKEY, 
						--Z.*, 
						ISNULL(SUM([CapitalNonMobilization]),0) AS SpotNonMobCap,
						ISNULL(MAX([CapitalMobilizationRate]),0) AS SpotRate,
						ISNULL(SUM(BaseTime),0) AS SpotBaseTime,
						ISNULL(MAX([MobilizationTime]),0) AS SpotMobTime
				FROM    #Branches AS X
						LEFT JOIN 
						(
						  [COSTEST_CapitalCostsMobilizationRatesAndTimes] AS Z
				          INNER JOIN
						  REHAB.GIS.REHAB_Segments AS Y
						  ON  Z.ID = Y.ID
						      AND
						      Y.cutno > 0
						      --@LineAtYearSpots
						      AND
						      (
						        [action] = 3
						      )
						)
						ON  X.Compkey = Z.COMPKEY
							AND
							Z.[type] = 'Spot'
							AND
							Y.fail_yr_seg  > X.[InitialFailYear] + X.LineAtYear
				GROUP BY X.COMPKEY
				
  --On a reactive liner job after a reactive spot job, only type 3 spots are replaced          
  UPDATE  #Branches
  SET     BPWSPfail02 = (TotalSpotLineCost*@EmergencyFactor+C.MaxSegmentCOFwithoutReplacement)*ISNULL(B.unit_multiplier,0) 
  FROM    (
            SELECT Table1.COMPKEY, 
                   (ISNULL(NonMobCap,0) + LineNonMobCap) 
                   + (CASE WHEN ISNULL(Rate,0) > ISNULL(LineRate,0) THEN ISNULL(Rate,0) ELSE ISNULL(LineRate,0) END)
                   * (
                       CASE WHEN ISNULL(MobTime,0) > ISNULL(LineMobTime,0) THEN ISNULL(MobTime,0) ELSE ISNULL(LineMobTime,0) END
                       +
                       (ISNULL(BaseTime,0) + LineBaseTime)
                     )/@HoursPerDay AS TotalSpotLineCost
            FROM   #Costs AS Table1
            INNER JOIN
            (
              SELECT  Compkey,
                      [CapitalNonMobilization] AS LineNonMobCap,
				      [CapitalMobilizationRate] AS LineRate,
					  BaseTime AS LineBaseTime,
					  [MobilizationTime] AS LineMobTime
              FROM    [COSTEST_CapitalCostsMobilizationRatesAndTimes]
              WHERE   [type] = 'Line'
                      AND 
                      ID < 40000000
            ) AS Table2
            ON Table1.Compkey = Table2.Compkey
          ) AS A
          INNER JOIN  
          #Branches AS C
          ON  A.Compkey = C.Compkey
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @StdDevNewSpot = B.std_dev
              AND 
              C.InitialFailYear + C.LineAtYear = B.failure_yr
              
  UPDATE  #Branches
  SET     BPWSPfail03 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @StdDevNewLiner = B.std_dev
              AND 
              A.InitialFailYear + A.LineAtYear + @RULNewLiner = B.failure_yr  

  UPDATE  #Branches
  SET     BPWSPfail04 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @MaxStdDev = B.std_dev
              AND 
              A.InitialFailYear + A.LineAtYear + @RULNewLiner + @RULNewWholePipe = B.failure_yr      
 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------
 --APW
 ----------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------------------------
 UPDATE   #Branches
  SET     APWOC01 = A.ReplaceCost
  FROM    #Branches AS A

  
  UPDATE  #Branches
  SET     APWOC02 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @MaxStdDev = B.std_dev
              AND 
              @thisYear + @RULNewWholePipe= B.failure_yr 
  
  --On a proactive liner job, just replace all type 3 spots
  UPDATE  #Branches
  SET     APWCIPP01 = (TotalSpotLineCost)
  FROM    (
            SELECT Table1.COMPKEY, 
                   (ISNULL(SpotNonMobCap,0) + LineNonMobCap) 
                   + (CASE WHEN ISNULL(SpotRate,0) > ISNULL(LineRate,0) THEN ISNULL(SpotRate,0) ELSE ISNULL(LineRate,0) END)
                   * (
                       CASE WHEN ISNULL(SpotMobTime,0) > ISNULL(LineMobTime,0) THEN ISNULL(SpotMobTime,0) ELSE ISNULL(LineMobTime,0) END
                       +
                       (ISNULL(SpotBaseTime,0) + LineBaseTime)
                     )/@HoursPerDay AS TotalSpotLineCost
            FROM
            (
				SELECT  Z.compkey, 
						SUM([CapitalNonMobilization]) AS SpotNonMobCap,
						MAX([CapitalMobilizationRate]) AS SpotRate,
						SUM(BaseTime) AS SpotBaseTime,
						MAX([MobilizationTime]) AS SpotMobTime
				FROM    REHAB.GIS.REHAB_Segments AS Z
						INNER JOIN
						[COSTEST_CapitalCostsMobilizationRatesAndTimes] AS ZZ1
						ON  Z.ID = ZZ1.ID
						    AND
						    ZZ1.[type] = 'Spot'
						INNER JOIN
						#Branches AS X
						ON  Z.compkey = X.compkey 
				WHERE   Z.cutno > 0
						AND
						(
						  [action] = 3
						)
				GROUP BY Z.compkey
            ) AS Table1
            INNER JOIN
            (
              SELECT  Compkey,
                      [CapitalNonMobilization] AS LineNonMobCap,
				      [CapitalMobilizationRate] AS LineRate,
					  BaseTime AS LineBaseTime,
					  [MobilizationTime] AS LineMobTime
              FROM    [COSTEST_CapitalCostsMobilizationRatesAndTimes]
              WHERE   [type] = 'Line'
                      AND 
                      ID < 40000000
            ) AS Table2
            ON Table1.Compkey = Table2.Compkey
          ) AS A
          INNER JOIN  
          #Branches AS C
          ON  A.Compkey = C.Compkey
               
  UPDATE  #Branches
  SET     APWCIPP02 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @StdDevNewLiner = B.std_dev
              AND 
              @thisYear + @RULNewLiner = B.failure_yr
              
  UPDATE  #Branches
  SET     APWCIPP03 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @MaxStdDev = B.std_dev
              AND 
              @thisYear + @RULNewLiner +@RULNewWholePipe = B.failure_yr
  
  UPDATE  #Branches
  SET     APWSP01 = A.SpotCost01
  FROM    #Branches AS A
  
  UPDATE  #Branches
  SET     LineAtYearAPW = @LineAtYearSpots
  FROM    #Branches AS A
  WHERE   A.SpotCost02 > 0
  
  UPDATE  #Branches
  SET     LineAtYearAPW = @LineAtYearNoSpots
  FROM    #Branches AS A
  WHERE   ISNULL(A.SpotCost02,0) = 0
   
  --This is a reactive liner year after a proactive spot year.  Replace only type 3 spots           
  UPDATE  #Branches
  SET     APWSP02 = (TotalSpotLineCost*@EmergencyFactor+C.MaxSegmentCOFwithoutReplacement)*ISNULL(B.unit_multiplier,0) 
  FROM    (
            SELECT Table1.COMPKEY, 
                   (ISNULL(SpotNonMobCap,0) + LineNonMobCap) 
                   + (CASE WHEN ISNULL(SpotRate,0) > ISNULL(LineRate,0) THEN ISNULL(SpotRate,0) ELSE ISNULL(LineRate,0) END)
                   * (
                       CASE WHEN ISNULL(SpotMobTime,0) > ISNULL(LineMobTime,0) THEN ISNULL(SpotMobTime,0) ELSE ISNULL(LineMobTime,0) END
                       +
                       (ISNULL(SpotBaseTime,0) + LineBaseTime)
                     )/@HoursPerDay AS TotalSpotLineCost
            FROM
            (
				SELECT  X.COMPKEY, 
        --Z.*, 
        ISNULL(SUM([CapitalNonMobilization]),0) AS SpotNonMobCap,
		ISNULL(MAX([CapitalMobilizationRate]),0) AS SpotRate,
		ISNULL(SUM(BaseTime),0) AS SpotBaseTime,
		ISNULL(MAX([MobilizationTime]),0) AS SpotMobTime
FROM    #Branches AS X
        LEFT JOIN 
        (
          [COSTEST_CapitalCostsMobilizationRatesAndTimes] AS Z
          INNER JOIN
          REHAB.GIS.REHAB_Segments AS Y
		  ON  Z.ID = Y.ID
		  AND
		  Y.cutno > 0
		  --@LineAtYearSpots
		  AND
		  (
		    [action] = 3
		  )
		)
		ON  X.Compkey = Z.COMPKEY
            AND
            Z.[type] = 'Spot'
            AND
		    Y.fail_yr_seg > @thisYear + @SpotRotationFrequency
GROUP BY X.COMPKEY
            ) AS Table1
            INNER JOIN
            (
              SELECT  Compkey,
                      [CapitalNonMobilization] AS LineNonMobCap,
				      [CapitalMobilizationRate] AS LineRate,
					  BaseTime AS LineBaseTime,
					  [MobilizationTime] AS LineMobTime
              FROM    [COSTEST_CapitalCostsMobilizationRatesAndTimes]
              WHERE   [type] = 'Line'
                      AND 
                      ID < 40000000
            ) AS Table2
            ON Table1.Compkey = Table2.Compkey
          ) AS A
          INNER JOIN  
          #Branches AS C
          ON  A.Compkey = C.Compkey
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @StdDevNewSpot = B.std_dev
              AND 
              @thisYear + C.LineAtYearAPW = B.failure_yr

			
              
  UPDATE  #Branches
  SET     APWSP03 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @StdDevNewLiner = B.std_dev
              AND 
              @thisYear + A.LineAtYearAPW + @RULNewLiner = B.failure_yr  

  UPDATE  #Branches
  SET     APWSP04 = (A.ReplaceCost*@EmergencyFactor+A.MaxSegmentCOFwithoutReplacement)* ISNULL(B.unit_multiplier,0)
  FROM    #Branches AS A
          INNER JOIN  
          REHAB_UnitMultiplierTable AS B
          ON  @MaxStdDev = B.std_dev
              AND 
              @thisYear + A.LineAtYearAPW + @RULNewLiner + @RULNewWholePipe = B.failure_yr             
  --------------------------------------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------------------
  --nBCR Section
  --The nBCR names start with nBCR, then underscore, and the assumed ASM solution, then underscore, then the possible alternatives
  --------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------- 
  UPDATE  #Branches
  SET     nBCR_OC_OC = ((BPWOCfail01+ISNULL(BPWOCfail02,0)) - (APWOC01+ISNULL(APWOC02,0)))/(APWOC01+ISNULL(APWOC02,0)),
          BPWOC = BPWOCfail01+ISNULL(BPWOCfail02,0),
          BPWCIPP = BPWCIPPfail01+BPWCIPPfail02+ISNULL(BPWCIPPfail03,0),
          BPWSP = BPWSPfail01+BPWSPfail02+ISNULL(BPWSPfail03,0)+ISNULL(BPWSPfail04,0),
          APWOC = APWOC01+ISNULL(APWOC02,0),
          APWCIPP = APWCIPP01+APWCIPP02+ISNULL(APWCIPP03,0),
          APWSP = APWSP01+APWSP02+ISNULL(APWSP03,0)+ISNULL(APWSP04,0)    
  
  UPDATE  #Branches
  SET     nBCR_OC_CIPP = ISNULL(((BPWOCfail01+ISNULL(BPWOCfail02,0))-(APWCIPP01+APWCIPP02+ISNULL(APWCIPP03,0)))/APWCIPP, -10)       
  
  UPDATE  #Branches
  SET     nBCR_OC_SP = ISNULL(((BPWOCfail01+ISNULL(BPWOCfail02,0))-(APWSP01+APWSP02+ISNULL(APWSP03,0)+ISNULL(APWSP04,0)))/APWSP, -10)
  
  UPDATE  #Branches
  SET     nBCR_CIPP_OC = ISNULL(((BPWCIPPfail01+BPWCIPPfail02+ISNULL(BPWCIPPfail03,0)) - (APWOC01+ISNULL(APWOC02,0)))/APWOC, -10)
  
  UPDATE  #Branches
  SET     nBCR_CIPP_CIPP = ISNULL(((BPWCIPPfail01+BPWCIPPfail02+ISNULL(BPWCIPPfail03,0)) - (APWCIPP01+APWCIPP02+ISNULL(APWCIPP03,0)))/APWCIPP, -10)           
  
  UPDATE  #Branches
  SET     nBCR_CIPP_SP = ISNULL(((BPWCIPPfail01+BPWCIPPfail02+ISNULL(BPWCIPPfail03,0)) - (APWSP01+APWSP02+ISNULL(APWSP03,0)+ISNULL(APWSP04,0)))/APWSP, -10)           
  
  UPDATE  #Branches
  SET     nBCR_SP_OC = ISNULL(((BPWSPfail01+BPWSPfail02+ISNULL(BPWSPfail03,0)+ISNULL(BPWSPfail04,0)) - (APWOC01+ISNULL(APWOC02,0)))/APWOC, -10)           
  
  UPDATE  #Branches
  SET     nBCR_SP_CIPP = ISNULL(((BPWSPfail01+BPWSPfail02+ISNULL(BPWSPfail03,0)+ISNULL(BPWSPfail04,0)) - (APWCIPP01+APWCIPP02+ISNULL(APWCIPP03,0)))/APWCIPP, -10)           
  
  UPDATE  #Branches
  SET     nBCR_SP_SP = ISNULL(((BPWSPfail01+BPWSPfail02+ISNULL(BPWSPfail03,0)+ISNULL(BPWSPfail04,0)) - (APWSP01+APWSP02+ISNULL(APWSP03,0)+ISNULL(APWSP04,0)))/APWSP, -10)           
  
  
  --Update the main Branches table?  No, not yet, we still haven't found the best solution.  All we really have found here is 
  --the different nBCRs, BPWs and APWs.  The best solution is the highest nBCR of all valid solutions.
  --Which means we need to run 12 as well
  
  
  UPDATE  A
  SET     nBCR_OC_CIPP = NULL,
          nBCR_CIPP_OC = NULL,
          nBCR_CIPP_CIPP = NULL,
          nBCR_CIPP_SP = NULL,
          nBCR_SP_CIPP = NULL,
          problems = ISNULL(problems, '') + ', extensive surcharge'
  FROM    #Branches AS A
          INNER JOIN
          REHAB_SURCHARGE AS B
          ON  B.COMPKEY = A.COMPKEY
              AND
              CAST(B.USSurch AS FLOAT) >= @unacceptableSurchargeFootage
  
  --Sagging
  UPDATE  A
  SET     nBCR_OC_CIPP = NULL,
          nBCR_OC_SP = NULL,
          nBCR_CIPP_OC = NULL,
          nBCR_CIPP_CIPP = NULL,
          nBCR_CIPP_SP = NULL,
          nBCR_SP_CIPP = NULL,
          nBCR_SP_OC = NULL,
          nBCR_SP_SP = NULL,
          problems = ISNULL(problems, '') + ', extensive sagging'
FROM    #Branches AS A
INNER JOIN
(
SELECT A.*, B.[Length], A.LengthSag/B.[length] AS SagFraction
FROM
(
SELECT COMPKEY, SUM(SumOfLength) AS LengthSag
FROM
(
SELECT B.GlobalID, MAX(A.COMPKEY) AS COMPKEY, MAX(SumOfLength) AS SumOfLength
FROM
(
  SELECT  COMPKEY, 
          DISTFROM,
          SumOfLength
  FROM    
  (
    SELECT  A.COMPKEY, 
            A.COMPDTTM,
            Observations.DISTFROM, 
            Observations.DISTTO, 
            CASE 
              WHEN Observations.DISTTO - Observations.DISTFROM < 10 
              THEN 10 
              ELSE Observations.DISTTO - Observations.DISTFROM 
            END AS SumOfLength, 
            Observations.OBSEVKEY, 
            TypeOB.OBCODE, 
            TYPEOBSEV.SEVERITY
    FROM    
    (
       SELECT  COMPKEY, 
               Observations.INSPKEY, 
               COMPDTTM, 
               RANK() OVER(PARTITION BY COMPKEY ORDER BY COMPDTTM DESC) AS theRank, 
               COUNT(*) AS TheCount
       FROM    --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVICEINSP] AS InspHist
               HA8_SMNSERVICEINSP AS InspHist
               INNER JOIN
               --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVINSPOB] AS Observations
               HA8_SMNSERVINSPOB AS Observations
               ON  InspHist.INSPKEY = Observations.INSPKEY
       GROUP BY COMPKEY, 
                Observations.INSPKEY, 
                COMPDTTM
    ) AS A
    INNER JOIN 
    --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVINSPOB] AS Observations
    HA8_SMNSERVINSPOB AS Observations
    ON  A.INSPKEY = Observations.INSPKEY
        INNER JOIN
        --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVINSPTYPEOB] AS TYPEOB
        HA8_SMNSERVINSPTYPEOB AS TYPEOB
        ON  TYPEOB.OBKEY = Observations.OBKEY
            INNER JOIN
            HA8_SMNSERVINSPTYPEOBSEV AS TYPEOBSEV
            ON  TYPEOBSEV.OBSEVKEY = Observations.OBSEVKEY
    WHERE   A.theRank = 1
  ) AS GroupDefects
  WHERE  GroupDefects.SEVERITY='A25' 
         OR 
         GroupDefects.SEVERITY='B50'
         OR 
         GroupDefects.SEVERITY='CUW'
) AS A
INNER JOIN 
[GIS].[REHAB_Segments] AS B 
ON  A.COMPKEY = B.COMPKEY
    AND 
    B.ID >= 40000000
    AND 
    B.fm <= A.DISTFROM
    AND
    B.to_ > A.DISTFROM
WHERE (
        remarks = 'BES'
        OR
        remarks = '_BES'
      )
GROUP BY GLOBALID
) AS X
GROUP BY COMPKEY
) AS A
INNER JOIN
[GIS].[REHAB_Segments] AS B
ON A.COMPKEY = B.compkey
AND B.ID < 40000000
WHERE A.LengthSag/B.[length] > @unacceptableSagFraction
) AS Results
ON Results.COMPKEY = A.COMPKEY

  --Ovaling
  UPDATE  A
  SET     nBCR_OC_CIPP = NULL,
          nBCR_OC_SP = NULL,
          nBCR_CIPP_OC = NULL,
          nBCR_CIPP_CIPP = NULL,
          nBCR_CIPP_SP = NULL,
          nBCR_SP_CIPP = NULL,
          nBCR_SP_OC = NULL,
          nBCR_SP_SP = NULL,
          problems = ISNULL(problems, '') + ', extensive ovaling'
FROM    #Branches AS A
INNER JOIN
(
SELECT A.*, B.[Length], A.LengthOval/B.[length] AS OvalFraction
FROM
(
SELECT COMPKEY, SUM(SumOfLength) AS LengthOval
FROM
(
SELECT B.GlobalID, MAX(A.COMPKEY) AS COMPKEY, MAX(SumOfLength) AS SumOfLength
FROM
(
  SELECT  COMPKEY, 
          DISTFROM,
          SumOfLength
  FROM    
  (
    SELECT  A.COMPKEY, 
            A.COMPDTTM,
            Observations.DISTFROM, 
            Observations.DISTTO, 
            CASE 
              WHEN Observations.DISTTO - Observations.DISTFROM < 10 
              THEN 10 
              ELSE Observations.DISTTO - Observations.DISTFROM 
            END AS SumOfLength, 
            Observations.OBSEVKEY, 
            TypeOB.OBCODE, 
            TYPEOBSEV.SEVERITY
    FROM    
    (
       SELECT  COMPKEY, 
               Observations.INSPKEY, 
               COMPDTTM, 
               RANK() OVER(PARTITION BY COMPKEY ORDER BY COMPDTTM DESC) AS theRank, 
               COUNT(*) AS TheCount
       FROM    --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVICEINSP] AS InspHist
               HA8_SMNSERVICEINSP AS InspHist
               INNER JOIN
               --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVINSPOB] AS Observations
               HA8_SMNSERVINSPOB AS Observations
               ON  InspHist.INSPKEY = Observations.INSPKEY
       GROUP BY COMPKEY, 
                Observations.INSPKEY, 
                COMPDTTM
    ) AS A
    INNER JOIN 
    --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVINSPOB] AS Observations
    HA8_SMNSERVINSPOB AS Observations
    ON  A.INSPKEY = Observations.INSPKEY
        INNER JOIN
        --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVINSPTYPEOB] AS TYPEOB
        HA8_SMNSERVINSPTYPEOB AS TYPEOB
        ON  TYPEOB.OBKEY = Observations.OBKEY
            INNER JOIN
            --[HANSEN8].[ASSETMANAGEMENT_SEWER].[SMNSERVINSPTYPEOBSEV] AS TYPEOBSEV
            HA8_SMNSERVINSPTYPEOBSEV AS TYPEOBSEV
            ON  TYPEOBSEV.OBSEVKEY = Observations.OBSEVKEY
    WHERE   A.theRank = 1
  ) AS GroupDefects
  WHERE  GroupDefects.SEVERITY='BRKO' 
         OR 
         GroupDefects.SEVERITY='OS'
) AS A
INNER JOIN 
[GIS].[REHAB_Segments] AS B 
ON  A.COMPKEY = B.COMPKEY
    AND 
    B.ID >= 40000000
    AND 
    B.fm <= A.DISTFROM
    AND
    B.to_ > A.DISTFROM
WHERE (
        remarks = 'BES'
        OR
        remarks = '_BES'
      )
GROUP BY GLOBALID
) AS X
GROUP BY COMPKEY
) AS A
INNER JOIN
[GIS].[REHAB_Segments] AS B
ON A.COMPKEY = B.compkey
AND B.ID < 40000000
WHERE A.LengthOval/B.[length] > @unacceptableOvallingFraction
) AS Results
ON Results.COMPKEY = A.COMPKEY
   
  --Compare all of the valid nBCR values from #Branches.
  --The maximum value is the best primary solution (BPW solution).
  --There may be problems with null nBCRs here, but I dont know
  UPDATE  A
  SET     A.ASM_Gen3Solution = B.BaseRiskSolution,
          A.ASM_Gen3SolutionnBCR = B.maxnBCR
  FROM    #Branches AS A
          INNER JOIN
          (
              SELECT  A.Compkey,
					  maxnBCR,
					  CASE
						WHEN maxnBCR = [nBCR_OC_OC]
							 OR
							 maxnBCR = [nBCR_CIPP_OC]
							 OR
							 maxnBCR = [nBCR_SP_OC]
						THEN 'OC' 
						WHEN maxnBCR = [nBCR_OC_SP]
							 OR
							 maxnBCR = [nBCR_CIPP_SP]
							 OR
							 maxnBCR = [nBCR_SP_SP]
						THEN 'SP'
						WHEN maxnBCR = [nBCR_OC_CIPP]
							 OR
							 maxnBCR = [nBCR_CIPP_CIPP]
							 OR
							 maxnBCR = [nBCR_SP_CIPP]
						THEN 'CIPP'
					  END AS BaseRiskSolution
			  FROM    #Branches AS A
					  INNER JOIN
					  (
						SELECT  Compkey,
								(
								  SELECT  Max(v) 
								  FROM    (
											VALUES ([nBCR_OC_OC]),
												   ([nBCR_OC_CIPP]),
												   ([nBCR_OC_SP]),
												   ([nBCR_CIPP_OC]),
												   ([nBCR_CIPP_CIPP]),
												   ([nBCR_CIPP_SP]),
												   ([nBCR_SP_OC]),
												   ([nBCR_SP_CIPP]),
												   ([nBCR_SP_SP])
										  ) AS value(v)
								) as [MaxnBCR]
						FROM    #Branches
					  ) AS B
					  ON  A.COMPKEY = B.COMPKEY
          ) AS B
          ON A.Compkey = B.Compkey
          
          
  SET @thisYear = @thisYear + 1
  DROP TABLE #Costs
  
  UPDATE  A
  SET     A.ASMFailureAction = B.ASM_Gen3Solution
  FROM    REHAB.GIS.REHAB_Branches AS A
          INNER JOIN
          #Branches AS B
          ON  A.Compkey = B.Compkey 
  
  
END



DROP TABLE #FailureYears
DROP TABLE #Branches
  
END
GO
