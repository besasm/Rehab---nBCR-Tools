USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_0CHECKS]    Script Date: 06/28/2011 16:24:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [ROSE\issacg].[USP_REHAB_0CHECKS]
AS
BEGIN
	SELECT TOP (1) STARTDTTM FROM [SIRTOBY].[HANSEN].[IMSV7].INSMNFT order by STARTDTTM desc
END
