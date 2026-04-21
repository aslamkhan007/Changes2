
--select  * From tbl_Industry_BasicCafDetails_ErrorLog

--select * From tbl_Industry_BasicCafDetails_ProcessStatus

--select * From tbl_Industry_BasicCafDetails_History

--select * from tbl_WorkIntimation_NameOfOwner_Updation_Log
--select * From tbl_RegistrationSiteOwner_NameOfOwner_Updation_Log


IF OBJECT_ID('dbo.tbl_Industry_BasicCafDetails_History', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_Industry_BasicCafDetails_History
    (
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        PreviousBusinessEntity NVARCHAR(500) NULL,
        CurrentBusinessEntity NVARCHAR(500) NULL,
        PreviousBusinessEntityType NVARCHAR(200) NULL,
        CurrentBusinessEntityType NVARCHAR(200) NULL,
        PreviousSiteAddress NVARCHAR(1000) NULL,
        CurrentSiteAddress NVARCHAR(1000) NULL,
        PreviousDistrict NVARCHAR(200) NULL,
        CurrentDistrict NVARCHAR(200) NULL,
        PreviousBlock NVARCHAR(200) NULL,
        CurrentBlock NVARCHAR(200) NULL,
        PreviousVillage NVARCHAR(200) NULL,
        CurrentVillage NVARCHAR(200) NULL,
        PreviousCafPin NVARCHAR(20) NULL,
        CurrentCafPin NVARCHAR(20) NOT NULL,
        PreviousCafType NVARCHAR(100) NULL,
        CurrentCafType NVARCHAR(100) NULL,
        Status TINYINT NOT NULL CONSTRAINT DF_tbl_Industry_BasicCafDetails_History_Status DEFAULT (1),
        CreatedOn DATETIME NOT NULL CONSTRAINT DF_tbl_Industry_BasicCafDetails_History_CreatedOn DEFAULT (GETDATE()),
        ProcessedOn DATETIME NULL
    );

    CREATE INDEX IX_tbl_Industry_BasicCafDetails_History_CurrentCafPin
        ON dbo.tbl_Industry_BasicCafDetails_History(CurrentCafPin, Id DESC);
END;
GO

IF COL_LENGTH('dbo.tbl_Industry_BasicCafDetails_History', 'ProcessedOn') IS NULL
BEGIN
    ALTER TABLE dbo.tbl_Industry_BasicCafDetails_History
    ADD ProcessedOn DATETIME NULL;
END;
GO

IF OBJECT_ID('dbo.tbl_Industry_BasicCafDetails_ProcessStatus', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_Industry_BasicCafDetails_ProcessStatus
    (
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        CafPin NVARCHAR(20) NOT NULL,
        ProcessStatus TINYINT NOT NULL, 
        LastProcessedOn DATETIME NOT NULL CONSTRAINT DF_tbl_Industry_BasicCafDetails_ProcessStatus_LastProcessedOn DEFAULT (GETDATE()),
        LastSuccessOn DATETIME NULL,
        LastFailureOn DATETIME NULL
    );

    CREATE UNIQUE INDEX UX_tbl_Industry_BasicCafDetails_ProcessStatus_CafPin
        ON dbo.tbl_Industry_BasicCafDetails_ProcessStatus(CafPin);
END;
GO

IF OBJECT_ID('dbo.tbl_Industry_BasicCafDetails_ErrorLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_Industry_BasicCafDetails_ErrorLog
    (
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        CafPin NVARCHAR(20) NULL,
        EndpointUrl NVARCHAR(1000) NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        StackTrace NVARCHAR(MAX) NULL,
        CreatedOn DATETIME NOT NULL CONSTRAINT DF_tbl_Industry_BasicCafDetails_ErrorLog_CreatedOn DEFAULT (GETDATE())
    );

    CREATE INDEX IX_tbl_Industry_BasicCafDetails_ErrorLog_CafPin
        ON dbo.tbl_Industry_BasicCafDetails_ErrorLog(CafPin, Id DESC);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Industry_GetCafPinList_ForBasicCafDetails
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        LTRIM(RTRIM(cafPin)) AS cafPin
    FROM dbo.tbl_IndustryServices_IncomingJson_Log
    WHERE cafPin IS NOT NULL
      AND LTRIM(RTRIM(cafPin)) <> ''
	  and cafpin = '4659013320'
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Industry_GetFailedCafPinList_ForBasicCafDetails
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT
        ps.CafPin AS cafPin
    FROM dbo.tbl_Industry_BasicCafDetails_ProcessStatus ps
    WHERE ps.ProcessStatus = 0
      AND (
            ps.LastSuccessOn IS NULL  
            OR ps.LastFailureOn > ps.LastSuccessOn
          )
    ;
END;
GO


CREATE OR ALTER PROCEDURE dbo.sp_UpsertIndustryBasicCafProcessStatus
(
    @CafPin NVARCHAR(20),
    @ProcessStatus TINYINT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.tbl_Industry_BasicCafDetails_ProcessStatus WHERE CafPin = @CafPin)
    BEGIN
        UPDATE dbo.tbl_Industry_BasicCafDetails_ProcessStatus
        SET
            ProcessStatus = @ProcessStatus,
            LastProcessedOn = GETDATE(),
            LastSuccessOn = CASE WHEN @ProcessStatus = 1 THEN GETDATE() ELSE LastSuccessOn END,
            LastFailureOn = CASE WHEN @ProcessStatus = 0 THEN GETDATE() ELSE LastFailureOn END
        WHERE CafPin = @CafPin;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tbl_Industry_BasicCafDetails_ProcessStatus
        (
            CafPin, ProcessStatus, LastProcessedOn, LastSuccessOn, LastFailureOn
        )
        VALUES
        (
            @CafPin,
            @ProcessStatus,
            GETDATE(),
            CASE WHEN @ProcessStatus = 1 THEN GETDATE() ELSE NULL END,
            CASE WHEN @ProcessStatus = 0 THEN GETDATE() ELSE NULL END
        );
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_LogIndustryBasicCafDetailsError
(
    @CafPin NVARCHAR(20) = NULL,
    @EndpointUrl NVARCHAR(1000) = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @StackTrace NVARCHAR(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tbl_Industry_BasicCafDetails_ErrorLog
    (
        CafPin, EndpointUrl, ErrorMessage, StackTrace
    )
    VALUES
    (
        @CafPin, @EndpointUrl, @ErrorMessage, @StackTrace
    );
END;
GO



IF COL_LENGTH('dbo.tbl_WorkIntimation', 'BusinessEntityType') IS NULL
BEGIN
		ALTER TABLE tbl_WorkIntimation 
		ADD BusinessEntityType NVARCHAR(100);
END

GO

IF COL_LENGTH('dbo.tbl_RegistrationSiteOwner', 'BusinessEntityType') IS NULL
BEGIN
	ALTER TABLE tbl_RegistrationSiteOwner 
	ADD BusinessEntityType NVARCHAR(100);
END

GO

IF OBJECT_ID('dbo.tbl_WorkIntimation_History_ApiUpdation_Log', 'U') IS NULL
BEGIN

	CREATE TABLE [dbo].[tbl_WorkIntimation_History_ApiUpdation_Log](
		[LogID] [int] IDENTITY(1,1) NOT NULL,
		[WorkIntimationID] [nvarchar](255) NULL,
		[ModifiedBy] [nvarchar](50) NULL,
		[ModifiedDate] [datetime] NULL,
		[OldBusinessEntity] [nvarchar](255) NULL,
		[NewBusinessEntity] [nvarchar](255) NULL,
		[OldBusinessEntityType] [nvarchar](255) NULL,
		[NewBusinessEntityType] [nvarchar](255) NULL,
		[OldSiteAddress] [nvarchar](500) NULL,
		[NewSiteAddress] [nvarchar](500) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[LogID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]


	ALTER TABLE [dbo].[tbl_WorkIntimation_History_ApiUpdation_Log] ADD  DEFAULT (getdate()) FOR [ModifiedDate]

END


IF OBJECT_ID('dbo.tbl_RegistrationSiteOwner_History_ApiUpdation_Log', 'U') IS NULL
BEGIN
	CREATE TABLE [dbo].[tbl_RegistrationSiteOwner_History_ApiUpdation_Log](
		[LogID] [int] IDENTITY(1,1) NOT NULL,
		[ID] [int] NOT NULL,
		[OldBusinessEntity] [nvarchar](255) NULL,
		[NewBusinessEntity] [nvarchar](255) NULL,
		[OldBusinessEntityType] [nvarchar](255) NULL,
		[NewBusinessEntityType] [nvarchar](255) NULL,
		[OldSiteAddress] [nvarchar](500) NULL,
		[NewSiteAddress] [nvarchar](500) NULL,
		[ModifiedBy] [nvarchar](50) NULL,
		[ModifiedDate] [datetime] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[LogID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
END

ALTER TABLE [dbo].[tbl_RegistrationSiteOwner_History_ApiUpdation_Log] ADD  DEFAULT (getdate()) FOR [ModifiedDate]
GO


IF OBJECT_ID('sp_UpsertIndustryBasicCafDetailsHistory_MainTablesUpdate') IS NOT NULL
    DROP PROCEDURE sp_UpsertIndustryBasicCafDetailsHistory_MainTablesUpdate;
GO

CREATE PROCEDURE sp_UpsertIndustryBasicCafDetailsHistory_MainTablesUpdate
(
    @CurrentBusinessEntity NVARCHAR(200) = NULL,
    @CurrentBusinessEntityType NVARCHAR(100) = NULL,
    @CurrentSiteAddress NVARCHAR(800) = NULL,
    @PANNumber NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

	BEGIN TRY

    INSERT INTO tbl_WorkIntimation_History_ApiUpdation_Log
    (
        WorkIntimationID,
        OldBusinessEntity,
        NewBusinessEntity,
        OldBusinessEntityType,
        NewBusinessEntityType,
        OldSiteAddress,
        NewSiteAddress,
        ModifiedBy
    )
    SELECT
        Id,
        NameOfAgency,
        @CurrentBusinessEntity,
        BusinessEntityType,
        @CurrentBusinessEntityType,
        Address,
        @CurrentSiteAddress,
        @PANNumber
    FROM tbl_WorkIntimation
    WHERE PANNumber = @PANNumber
      AND PremisesType = 'Industry'
      AND Status = 1
      AND (
            ISNULL(NameOfAgency,'') <> ISNULL(@CurrentBusinessEntity,'')
         OR ISNULL(Address,'') <> ISNULL(@CurrentSiteAddress,'')
         OR ISNULL(BusinessEntityType,'') <> ISNULL(@CurrentBusinessEntityType,'')
      );

    UPDATE tbl_WorkIntimation
    SET 
        NameOfAgency = @CurrentBusinessEntity,
        Address = @CurrentSiteAddress,
        BusinessEntityType = @CurrentBusinessEntityType,
        ModiFiedBy = 'BySchedulerUpdate',
        ModifiedDate = GETDATE()
    WHERE PANNumber = @PANNumber
      AND PremisesType = 'Industry'
      AND Status = 1
      AND (
            ISNULL(NameOfAgency,'') <> ISNULL(@CurrentBusinessEntity,'')
         OR ISNULL(Address,'') <> ISNULL(@CurrentSiteAddress,'')
         OR ISNULL(BusinessEntityType,'') <> ISNULL(@CurrentBusinessEntityType,'')
      );


    INSERT INTO tbl_RegistrationSiteOwner_History_ApiUpdation_Log
    (
        ID,
        OldBusinessEntity,
        NewBusinessEntity,
        OldBusinessEntityType,
        NewBusinessEntityType,
        OldSiteAddress,
        NewSiteAddress,
        ModifiedBy
    )
    SELECT
        Id,
        NameOfAgency,
        @CurrentBusinessEntity,
        BusinessEntityType,
        @CurrentBusinessEntityType,
        Address,
        @CurrentSiteAddress,
        @PANNumber
    FROM tbl_RegistrationSiteOwner
    WHERE UserID = @PANNumber
      AND Status = 1
      AND (
            ISNULL(NameOfAgency,'') <> ISNULL(@CurrentBusinessEntity,'')
         OR ISNULL(Address,'') <> ISNULL(@CurrentSiteAddress,'')
         OR ISNULL(BusinessEntityType,'') <> ISNULL(@CurrentBusinessEntityType,'')
      );

    UPDATE tbl_RegistrationSiteOwner
    SET 
        NameOfAgency = @CurrentBusinessEntity,
        Address = @CurrentSiteAddress,
        BusinessEntityType = @CurrentBusinessEntityType,
        ModiFiedBy = 'BySchedulerUpdate',
        ModifiedDate = GETDATE()
    WHERE UserID = @PANNumber
      AND Status = 1
      AND (
            ISNULL(NameOfAgency,'') <> ISNULL(@CurrentBusinessEntity,'')
         OR ISNULL(Address,'') <> ISNULL(@CurrentSiteAddress,'')
         OR ISNULL(BusinessEntityType,'') <> ISNULL(@CurrentBusinessEntityType,'')
      );
	END TRY
	BEGIN CATCH
			SELECT 
			ERROR_MESSAGE() AS ErrorMessage,
			ERROR_LINE() AS ErrorLine,
			ERROR_PROCEDURE() AS ErrorProcedure;
		THROW;
	END CATCH

END;
GO

IF OBJECT_ID('sp_UpsertIndustryBasicCafDetailsHistory') IS NOT NULL
    DROP PROCEDURE sp_UpsertIndustryBasicCafDetailsHistory;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UpsertIndustryBasicCafDetailsHistory
(
    @CurrentBusinessEntity NVARCHAR(500) = NULL,
    @CurrentBusinessEntityType NVARCHAR(200) = NULL,
    @CurrentSiteAddress NVARCHAR(1000) = NULL,
    @CurrentDistrict NVARCHAR(200) = NULL,
    @CurrentBlock NVARCHAR(200) = NULL,
    @CurrentVillage NVARCHAR(200) = NULL,
    @CurrentCafPin NVARCHAR(20),
    @CurrentCafType NVARCHAR(100) = NULL,
    @IsHistoryChanged BIT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsHistoryChanged = 0;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE
            @PrevBusinessEntity NVARCHAR(500),
            @PrevBusinessEntityType NVARCHAR(200),
            @PrevSiteAddress NVARCHAR(1000),
            @PrevDistrict NVARCHAR(200),
            @PrevBlock NVARCHAR(200),
            @PrevVillage NVARCHAR(200),
            @PrevCafPin NVARCHAR(20),
            @PrevCafType NVARCHAR(100);

        SELECT TOP 1
            @PrevBusinessEntity = CurrentBusinessEntity,
            @PrevBusinessEntityType = CurrentBusinessEntityType,
            @PrevSiteAddress = CurrentSiteAddress,
            @PrevDistrict = CurrentDistrict,
            @PrevBlock = CurrentBlock,
            @PrevVillage = CurrentVillage,
            @PrevCafPin = CurrentCafPin,
            @PrevCafType = CurrentCafType
        FROM dbo.tbl_Industry_BasicCafDetails_History
        WHERE CurrentCafPin = @CurrentCafPin
        ORDER BY Id DESC;

        IF @PrevCafPin IS NULL
        BEGIN
            INSERT INTO dbo.tbl_Industry_BasicCafDetails_History
            (
                PreviousBusinessEntity, CurrentBusinessEntity,
                PreviousBusinessEntityType, CurrentBusinessEntityType,
                PreviousSiteAddress, CurrentSiteAddress,
                PreviousDistrict, CurrentDistrict,
                PreviousBlock, CurrentBlock,
                PreviousVillage, CurrentVillage,
                PreviousCafPin, CurrentCafPin,
                PreviousCafType, CurrentCafType,
                Status, ProcessedOn
            )
            VALUES
            (
                NULL, @CurrentBusinessEntity,
                NULL, @CurrentBusinessEntityType,
                NULL, @CurrentSiteAddress,
                NULL, @CurrentDistrict,
                NULL, @CurrentBlock,
                NULL, @CurrentVillage,
                NULL, @CurrentCafPin,
                NULL, @CurrentCafType,
                1, GETDATE()
            );

            SET @IsHistoryChanged = 1;
            EXEC sp_UpsertIndustryBasicCafDetailsHistory_MainTablesUpdate
                @CurrentBusinessEntity,
                @CurrentBusinessEntityType,
                @CurrentSiteAddress,
                @CurrentCafPin;

            COMMIT TRANSACTION;
            RETURN;
        END;

        IF ISNULL(@PrevBusinessEntity, '') <> ISNULL(@CurrentBusinessEntity, '')
           OR ISNULL(@PrevBusinessEntityType, '') <> ISNULL(@CurrentBusinessEntityType, '')
           OR ISNULL(@PrevSiteAddress, '') <> ISNULL(@CurrentSiteAddress, '')
        BEGIN
            INSERT INTO dbo.tbl_Industry_BasicCafDetails_History
            (
                PreviousBusinessEntity, CurrentBusinessEntity,
                PreviousBusinessEntityType, CurrentBusinessEntityType,
                PreviousSiteAddress, CurrentSiteAddress,
                PreviousDistrict, CurrentDistrict,
                PreviousBlock, CurrentBlock,
                PreviousVillage, CurrentVillage,
                PreviousCafPin, CurrentCafPin,
                PreviousCafType, CurrentCafType,
                Status, ProcessedOn
            )
            VALUES
            (
                @PrevBusinessEntity, @CurrentBusinessEntity,
                @PrevBusinessEntityType, @CurrentBusinessEntityType,
                @PrevSiteAddress, @CurrentSiteAddress,
                @PrevDistrict, @CurrentDistrict,
                @PrevBlock, @CurrentBlock,
                @PrevVillage, @CurrentVillage,
                @PrevCafPin, @CurrentCafPin,
                @PrevCafType, @CurrentCafType,
                1, GETDATE()
            );

            SET @IsHistoryChanged = 1;
            EXEC sp_UpsertIndustryBasicCafDetailsHistory_MainTablesUpdate
                @CurrentBusinessEntity,
                @CurrentBusinessEntityType,
                @CurrentSiteAddress,
                @CurrentCafPin;
        END

        UPDATE dbo.tbl_Industry_BasicCafDetails_History
        SET ProcessedOn = GETDATE()
        WHERE Id = (
            SELECT TOP 1 Id
            FROM dbo.tbl_Industry_BasicCafDetails_History
            WHERE CurrentCafPin = @CurrentCafPin
            ORDER BY Id DESC
        );
  
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO
GO
