USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_SET_SCHEMA_ISSACG]    Script Date: 06/28/2011 16:38:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [ROSE\issacg].[USP_SET_SCHEMA_ISSACG] (@username varchar(100))
AS
BEGIN

DECLARE @theUser varchar(100)
DECLARE @cmd varchar(256)
	SET @theUser = @username
	SET @cmd = 'ALTER USER ' +@theUser+' WITH DEFAULT_SCHEMA = [ROSE\issacg];'
	EXECUTE (@cmd)
END
