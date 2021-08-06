-- =============================================================================
-- DBMS Name      :    SQL Server
-- Script Name    :    update_stage_customers
-- Description    :    Build the staging table stage_customers
-- Generated by   :    WhereScape RED Version 8.5.1.0 (build 200517-023937)
-- Generated for  :    Partner Engaging Data 2021
-- Generated on   :    Wednesday, August 04, 2021 at 10:11:20
-- Author         :    GlennDobson
-- =============================================================================
-- Notes / History
--
CREATE PROCEDURE [SCHEMA.update_stage_customers].update_stage_customers
  @p_sequence         integer
, @p_job_name         varchar(256)
, @p_task_name        varchar(256)
, @p_job_id           integer
, @p_task_id          integer
, @p_return_msg       varchar(1024) OUTPUT
, @p_status           integer       OUTPUT
AS
  SET XACT_ABORT OFF  -- Turn off auto abort on errors
  SET NOCOUNT ON      -- Turn off row count messages

  --=====================================================
  -- Control variables used in most programs
  --=====================================================
  DECLARE
    @v_msgtext         varchar(1024) -- Text for audit_trail
  , @v_sql             nvarchar(255) -- Text for SQL statements
  , @v_set             integer       -- commit set
  , @v_analyze_flag    integer       -- analyze flag
  , @v_step            integer       -- return code
  , @v_update_count    integer       -- no of records updated
  , @v_insert_count    integer       -- no of records inserted
  , @v_count           integer       -- General counter
  , @v_db_code         varchar(10)   -- Database error code
  , @v_db_msg          varchar(1024) -- Database error message

  --=====================================================
  -- General Variables
  --=====================================================
  DECLARE
    @v_return_status   integer       -- Update result status
  , @v_getkey_status   integer       -- GetKey procedure status
  , @v_row_count       integer       -- General row count
  , @v_truncate_date   datetime      -- Used to set date to midnight
  , @v_dss_source_system_key integer -- Used for dimension joins
  , @v_dss_current_flag      char(1) -- Used for dimension joins
  , @v_dss_create_time       datetime  -- Used for date insert
  , @v_dss_update_time       datetime  -- Used for date insert

  

  --=====================================================
  -- MAIN
  --=====================================================
  SELECT @v_step = 100
  BEGIN TRY

  -- Set initial variable values
  SELECT
    @v_set          = 0
  , @v_analyze_flag = 0
  , @v_step         = 200
  , @v_update_count = 0
  , @v_insert_count = 0
  , @v_dss_source_system_key = 1
  , @v_dss_current_flag = 'Y'
  , @v_dss_create_time = GETDATE()
  , @v_dss_update_time = GETDATE()



  --=====================================================
  -- Delete all existing data from the staging table
  --=====================================================
  SET @v_sql = N'TRUNCATE TABLE stage_customers'
  EXEC @v_return_status = sp_executesql @v_sql

  --=======================================================
  -- Insert input records into stage_customers
  --=======================================================
  SET @v_step = 300
  
  BEGIN TRANSACTION
  
  INSERT INTO stage_customers WITH ( TABLOCK )
  (
    customer_name,
    dob,
    dss_record_source,
    dss_load_date,
    dss_create_time,
    dss_update_time
  )
  SELECT
    load_customers.customer_name,
    load_customers.dob,
    load_customers.dss_record_source,
    load_customers.dss_load_date,
    @v_dss_create_time,
    @v_dss_update_time
  FROM [TABLEOWNER].[load_customers] load_customers

  SELECT @v_insert_count = @@ROWCOUNT
  
  COMMIT


  --=====================================================
  -- All Done report the results
  --=====================================================
  
  -- WsWrkTask(job,task,seq,insert,update,replace,delete,discard,reject,error)
  EXEC WsWrkTask @p_job_id, @p_task_id, @p_sequence,
    @v_insert_count,@v_update_count,0,0,0,0,0

  -- Work out the return message
  SET @v_step = 400
  SET @p_status = 1
  SET @p_return_msg = 'stage_customers updated. '
    + CONVERT(varchar,@v_insert_count) + ' new records. '
    + CONVERT(varchar,@v_update_count) + ' records updated.'
    IF @v_update_count > 0
    BEGIN
      SET @p_return_msg = @p_return_msg + ' WARNING: Updated records indicate a non unique business key'
      SET @p_status = -1
    END

  RETURN 0
  END TRY
  BEGIN CATCH
    SET @p_status = -2
    SET @p_return_msg = SUBSTRING('stage_customers update FAILED with error '
      + CONVERT(varchar,ISNULL(ERROR_NUMBER(),0))
      + ' Step ' + CONVERT(varchar,ISNULL(@v_step,0))
      + '. Error Msg: ' + ERROR_MESSAGE(),1,1023)
  END CATCH
  IF XACT_STATE() <> 0
  BEGIN
    ROLLBACK TRANSACTION
  END
  RETURN 0
