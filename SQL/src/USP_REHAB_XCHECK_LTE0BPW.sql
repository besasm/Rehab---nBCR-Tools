USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_XCHECK_LTE0BPW]    Script Date: 06/28/2011 16:37:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [ROSE\issacg].[USP_REHAB_XCHECK_LTE0BPW] 

AS
BEGIN

--SELECT * FROM REHAB10FTSEGS WHERE GRADE_H5 = 3 AND MLINKID < 40000000
SELECT COMPKEY FROM REHAB10FTSEGS WHERE bpw <= 0
GROUP BY COMPKEY
--SELECT * FROM REHAB10FTSEGS WHERE bpw is null

END
