USE [SANDBOX]
GO
/****** Object:  StoredProcedure [ROSE\issacg].[USP_REHAB_ADDUNDISCRETIZEDPIPES]    Script Date: 06/28/2011 16:28:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [ROSE\issacg].[USP_REHAB_ADDUNDISCRETIZEDPIPES]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--objectid cannot be null
	--must ask albert about this
    --INSERT INTO REhab10FtSegs (OBJECTID, COMPKEY) SELECT 1, COMPKEY FROM REHAB_CompkeysOwnedByBESButNotDiscretized
    DELETE FROM REhab10FtSegs WHERE ObjectID = 1
END
