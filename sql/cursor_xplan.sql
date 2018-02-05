set echo off verify off

-- This script is a wrapper for DBMS_XPLAN.DISPLAY, using the
-- GV$SQL_PLAN_STATISTICS_ALL fixed view as the plan-table source. It's intended
-- as a RAC-aware replacement for the DBMS_XPLAN.DISPLAY_CURSOR function.
--
-- Usage:      @cursor_xplan [sql_id] [sql_child_number] [instance_number] [format]
--
-- Parameters: 1) sql_id            - defaults to last executed statement
--             2) sql_child_number  - defaults to 0 if sql_id was specified,
--                                    last executed statement otherwise
--             3) instance_number   - defaults to current instance
--             4) format            - defaults to "ALL IOSTATS LAST PEEKED_BINDS -BYTES -PROJECTION"
--
--             NOTE: To omit leading parameters, use a pair of double-quotes as a placeholder
--
-- Examples:   1) Display plan for last statement executed by the current session
--                NOTE: This requires SERVEROUTPUT set to OFF
--                ----------------------------------------------------------------
--                @cursor_xplan
--
--             2) Same, but with a non-default format
--                ----------------------------------------------------------------
--                @cursor_xplan "" "" "" "TYPICAL"
--
--             3) Display plan for a specific SQL ID
--                ----------------------------------------------------------------
--                @cursor_xplan buscq7na5byrt
--                @cursor_xplan buscq7na5byrt 1
--
--             4) Same, but for instance number 3
--                ----------------------------------------------------------------
--                @cursor_xplan buscq7na5byrt "" 3
--                @cursor_xplan buscq7na5byrt 1 3
--
--             5) Finally, one with all parameters specified
--                ----------------------------------------------------------------
--                @cursor_xplan buscq7na5byrt 1 3 "TYPICAL"
--
-- Versions:   This script is expected to work on all Oracle versions from 10.2 onward.
--             It was developed and tested primarily with 11.2.0.3 and 11.2.0.4, however,
--             so minor corrections might be required for other releases.
--
-- Privileges: SELECT on V$SESSION
--             SELECT on GV$SQL
--             SELECT on GV$SQL_PLAN_STATISTICS_ALL
--             EXECUTE on DBMS_XPLAN
--
-- Author:     Adric Norris
-- Version:    1.2
--

-- Get default values, in case the various parameters are omitted
--
set termout off
column prev_sql_id       new_value _default_sqlid
column prev_child_number new_value _default_child
column instance          new_value _default_instance
column format            new_value _default_format
select s.prev_sql_id, s.prev_child_number,
       sys_context('USERENV','INSTANCE') instance,
       'ALL IOSTATS LAST PEEKED_BINDS -BYTES -PROJECTION' format
   from v$session s
   where s.sid = sys_context('USERENV','SID');
column prev_sql_id       clear
column prev_child_number clear
column instance          clear
column format            clear

-- Initialize parameter variables in case the values aren't provided
-- (suppress prompting for values, in other words)
--
column 1 new_value 1
column 2 new_value 2
column 3 new_value 3
column 4 new_value 4
select NULL "1", NULL "2", NULL "3", NULL "4"
   from dual
   where 0 = 1;
column 1 clear
column 2 clear
column 3 clear
column 4 clear

-- Assign values to final variables. This will make later usage easier to follow, by
-- avoiding the need to wrap every reference with the NVL() function.
--
column sqlid    new_value _sqlid
column child    new_value _child
column instance new_value _instance
column format   new_value _format
select nvl( '&1', '&_default_sqlid' ) sqlid,
       case when '&1' is not NULL and '&2' is NULL     then '0'
            when '&1' is not NULL and '&2' is not NULL then trim( '&2' )
            else trim( '&_default_child' )
       end child,
       nvl( '&3', trim( &_default_instance ) ) instance,
       nvl( '&4', '&_default_format' ) format
   from dual;
column sqlid    clear
column child    clear
column instance clear
column format   clear
set termout on

-- Display some basic info about the SQL ID being processed, to roughly mimic the behaviour
-- of the DBMS_XPLAN.DISPLAY_CURSOR function.
--
set heading off
column seq noprint
select 1 seq, '--------------------------------------' text
   from dual
union all
select 2, 'SQL_ID  &_sqlid, child number &_child'
   from dual
union all
select 3, '--------------------------------------'
   from dual
   order by 1;
set heading on

-- Display SQL text for the selected ID, both for validation and to roughly mimic the output
-- of the DBMS_XPLAN.DISPLAY_CURSOR function.
-- NOTE: The amount of SQL text displayed is limited by the SET LONG value in effect for
--       your session.
--
-- In addition, [G]V$SQL and [G]V$SQL_PLAN_STATISTICS_ALL may include duplicate child cursor
-- numbers for a given SQL statement under 11.2.0.3, due to bug 14585499. We therefore need
-- to obtain the child cursor address, to ensure the DBMS_XPLAN.DISPLAY invocation below
-- doesn't produce duplicate/mangled output.
column address noprint new_value _address
column sql_text format a80 word_wrap
select rawtohex( s.address ) address,
       s.sql_fulltext sql_text
   from gv$sql s
   where s.inst_id      = &_instance
     and s.sql_id       = '&_sqlid'
     and s.child_number = &_child
     and s.is_obsolete  = 'N';
column address clear
column sql_text clear

-- time to make the donuts!!!
select * from table( dbms_xplan.display( 'gv$sql_plan_statistics_all', null, '&_format',
                                         q'[inst_id = &_instance and sql_id = '&_sqlid' and child_number = &_child and address=hextoraw( '&_address' )]'
                                       )
                   );

-- On second thought, let's not go to Camelot. 'Tis a silly place.
--
undefine _default_sqlid
undefine _default_child
undefine _default_instance
undefine _default_format
undefine _sqlid
undefine _child
undefine _instance
undefine _format
undefine _address
undefine 1
undefine 2
undefine 3
undefine 4
