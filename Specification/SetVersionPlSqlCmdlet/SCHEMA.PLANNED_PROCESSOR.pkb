CREATE OR REPLACE PACKAGE BODY "OPROC".PLANNED_PROCESSOR AS
--===========================================================================================================================
/*

    Project : GIS/OMS

Applic Name :

     Author : Russell

       Date :

Copyright (c) Ched Services

  Function :

Discussion :


===========================================================================*/

--Used to Identify Build
FileVersion VARCHAR2(20) := '4.1.mmmm.nnnn';--FileVersion

--==============================================================================
--
-- Package vars
--
m_ReminderMessagetype CONSTANT PLANNED_MESSAGE_VL.MESSAGE_TYPE%type := 'PL Reminder';
m_pl_completion_delay_in_min PLS_INTEGER := 30;


cursor m_settings_cur is
select * from (
select name,value from config
)
pivot (max(value) for name in (
    'DEBUG_PKG'                               as DEBUG_PKG
   ,'SDLC_ENVIRONMENT'                        as SDLC_ENVIRONMENT
   ,'PLANNED!PL_COMPLETION_DELAY_IN_MINUTES'  as PL_COMPLETION_DELAY_IN_MINUTES
));

m_settings m_settings_cur%rowtype;

gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';



--
--Private Procedure Prototypes
--

planned_processor_fail   EXCEPTION;
PRAGMA EXCEPTION_INIT (planned_processor_fail, -20998);

planned_processor_donetoday exception;
PRAGMA EXCEPTION_INIT (planned_processor_donetoday, -20997);

job_exists EXCEPTION;
pragma exception_init (job_exists,-27477 );

--=============================================================================
FUNCTION getVersion return varchar2
IS
begin
    return FileVersion;
end getVersion;


--=============================================================================
FUNCTION printf (p_msg in varchar2,
                  p_value1 in varchar2 := null,
                  p_value2 in varchar2 := null,
                  p_value3 in varchar2 := null,
                  p_value4 in varchar2 := null,
                  p_value5 in varchar2 := null,
                  p_value6 in varchar2 := null,
                  p_value7 in varchar2 := null,
                  p_value8 in varchar2 := null)
RETURN VARCHAR2
IS
  l_text varchar2(32000);
begin

  /*

  Purpose:    Print debug information (multiple values)

  Remarks:

  Who     Date        Description
  ------  ----------  -------------------------------------
  MBR     14.09.2006  Created

  */


  if (m_settings.debug_pkg = 'ON' ) then

    l_text:=p_msg;

    l_text:=replace(l_text, '%1', nvl (p_value1, '(blank)'));
    l_text:=replace(l_text, '%2', nvl (p_value2, '(blank)'));
    l_text:=replace(l_text, '%3', nvl (p_value3, '(blank)'));
    l_text:=replace(l_text, '%4', nvl (p_value4, '(blank)'));
    l_text:=replace(l_text, '%5', nvl (p_value5, '(blank)'));
    l_text:=replace(l_text, '%6', nvl (p_value6, '(blank)'));
    l_text:=replace(l_text, '%7', nvl (p_value7, '(blank)'));
    l_text:=replace(l_text, '%8', nvl (p_value8, '(blank)'));
  else
    l_text := null;
  END IF;

  RETURN l_text;
end printf;


--==============================================================================
FUNCTION Display_Settings RETURN sms_push_monitor_set
IS
/*
Diagnostic display of package. Only valid for this session
*/

c_func_name CONSTANT VARCHAR2(32) NOT NULL := 'DisplayStatus';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;

retval sms_push_monitor_set := sms_push_monitor_set();

PROCEDURE extend_assign (p_row_in IN sms_push_monitor_t)
IS
BEGIN
   retval.extend;
   retval(retval.last) := p_row_in;
END;

BEGIN

extend_assign(sms_push_monitor_t('FileVersion'                      ,$$plsql_unit ||' build version'                   , FileVersion       ));

extend_assign(sms_push_monitor_t('debug_pkg'                        ,$$plsql_unit ||' debug_pkg '                      , m_settings.debug_pkg ));
extend_assign(sms_push_monitor_t('logger'                           ,$$plsql_unit ||' logging '                        , logger.get_pref('LEVEL')));
extend_assign(sms_push_monitor_t('pl_completion_delay_in_minutes'   ,$$plsql_unit ||' pl_completion_delay_in_minutes ' , m_settings.pl_completion_delay_in_minutes));

$if PACKAGE_CONFIG.UNIT_TEST $then
extend_assign(sms_push_monitor_t('PACKAGE_CONFIG.UNIT_TEST'   ,$$plsql_unit ||' Unit Testing config is '  , CASE PACKAGE_CONFIG.UNIT_TEST      WHEN TRUE THEN 'TRUE' ELSE 'FALSE' END ));
$end

RETURN retval;

EXCEPTION
   WHEN OTHERS THEN
      logger.log_error(
          p_text   =>  'Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         --,p_params  => l_params
         );
END Display_Settings;


--=============================================================================
PROCEDURE send_reminder_cancellation
IS
/*
Send a cancellation message if the PON projects start_status has changed to cancelled using the Planned Outage Notification application
Check the PLANNED_STATUS table since last invocation and see what changed.
Called cyclicly from ControlM every nn minutes.(interval set by controlM depending on business requirements)
Manages the last process highwater mark in PLANNED_STATUS
*/
c_func_name  constant varchar2(32) not null := 'send_reminder_cancellation';
l_scope  logger_logs.scope%type := gc_scope_prefix ||c_func_name;
l_params logger.tab_param;
BEGIN
   logger.append_param(l_params, 'l_message_type', l_message_type);
   logger.log_information('START{', l_scope );


   logger.log_information('END}', l_scope);
   /* commit;  -- the caller do the commit; migh help testing */
   exception
   when others then
      debug_pkg.printf( 'Unhandled Exception %1:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE, l_scope);
      logger.log_error(
          p_text   =>  'Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         );
      raise planned_processor_fail;
end send_reminder_cancellation;



--=============================================================================
PROCEDURE main
IS
/*
Send the daily Planned Reminder Notices
Schedule the Completed Reminder Notices

Executed once per day at a time the business decides.
Called from ControlM

*/
c_func_name  constant varchar2(32) not null := 'main';
l_scope  logger_logs.scope%type := gc_scope_prefix ||c_func_name;


BEGIN
   logger.log_information('START{', l_scope );

   logger.log_information('END}', l_scope);

EXCEPTION
   when planned_processor_fail then
     ROLLBACK;
     raise;
   WHEN planned_processor_donetoday THEN
      dbms_output.put_line('ERR> Planned Reminder Messages have been generated today.');
      raise_application_error(SQLCODE,'ERR>' || SQLERRM || ' Planned Reminder Messages have been generated today.');
   WHEN OTHERS THEN
      logger.log_error(
          p_text   =>  'Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         );
     rollback;
     RAISE;
END main;



--==============================================================================
PROCEDURE init
IS
   /* Initialise the parameter the package relies on*/
c_func_name CONSTANT VARCHAR2(32) NOT NULL := 'Init';
l_scope logger_logs.scope%type := gc_scope_prefix || c_func_name;

BEGIN
  logger.log('START{', l_scope);

  BEGIN
     BEGIN
        for r in m_settings_cur loop
             m_settings := r;
        end loop;
        IF m_settings.debug_pkg = 'ON' THEN debug_pkg.debug_on; ELSE debug_pkg.debug_off;END IF;
     EXCEPTION
        WHEN OTHERS THEN
           debug_pkg.debug_on;
     END;

     m_pl_completion_delay_in_min := 30;
     IF m_settings.PL_COMPLETION_DELAY_IN_MINUTES IS NOT NULL THEN
        m_pl_completion_delay_in_min := m_settings.PL_COMPLETION_DELAY_IN_MINUTES;
     END IF;


  EXCEPTION
     WHEN OTHERS THEN
        debug_pkg.debug_on;
  END;

   debug_pkg.printf( $$plsql_unit || ' - Package Initialisation  = %1', l_scope);
   logger.log('END}', l_scope);
 EXCEPTION
   WHEN OTHERS THEN
      logger.log_error(
         p_text   =>  'Exception: Initialisation failed. ' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
        ,p_scope   => l_scope
    );
END init;


--==============================================================================

-- Initialization section
BEGIN
   init;
EXCEPTION
  WHEN OTHERS THEN
    logger.LOG_ERROR ( 'Exception: ' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE,m_settings.debug_pkg);
    RAISE;
END PLANNED_PROCESSOR;
/



