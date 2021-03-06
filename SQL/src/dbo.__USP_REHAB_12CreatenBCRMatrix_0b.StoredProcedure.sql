USE [REHAB]
GO
/****** Object:  StoredProcedure [dbo].[__USP_REHAB_12CreatenBCRMatrix_0b]    Script Date: 02/12/2016 09:07:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[__USP_REHAB_12CreatenBCRMatrix_0b] @AsOfDate datetime = NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF @AsOfDate IS NULL
   SET @AsOfDate = GETDATE()
   
  DECLARE @unacceptableSurchargeFootage FLOAT = 1.0
  DECLARE @unacceptableOvallingFraction FLOAT = 0.1
  DECLARE @unacceptableSagFraction FLOAT = 0.1
  
  UPDATE  A
  SET     problems = ''
  FROM    #Branches AS A
   
  
  --For each pipe, there is a valid nBCR matrix.  For example, some pipes cannot
  --be lined, some pipes cannot be spot repaired, and some pipes must be open cut only.
  --In order to create this matrix, we need the following information:
  
  --(1) Is the pipe surcharged? (Open cut or spot)
  --(2) Is the pipe sagging more than 10%? (OC only)
  --(3) Is the pipe ovaling more than 10% (OC only)
  --For now, these three situations need to be resolved.  The first one to resolve will be (1).
  --To trim the matrix, we null out the values for those pipes that include options from those scenarios:
  
  
  --Surcharging
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
  
          
END
GO
