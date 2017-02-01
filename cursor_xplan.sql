set echo off verify off

-- This script is a wrapper for DBMS_XPLAN.DISPLAY, using the 
-- GV$SQL_PLAN_STATISTICS_ALL fixed view as the plan-table source. It's intended
-- as a RAC-aware replacement for the DBMS_XPLAN.DISPLAY_CURSOR function... at
-- least for the common case.
--
-- Author:     Adric Norris
-- Version:    1.0
--

-- Determine the current instance number, which will be used as the default value for
-- the instance owning the cursor of interest. Also generate a pad value based upon
-- the number of digits, to ensure that prompts line up.
set termout off
column instance noprint new_value instance format a2
column padding  noprint new_value padding  format a2
select sys_context( 'USERENV', 'INSTANCE' ) instance,
       rpad( '.', length( sys_context( 'USERENV', 'INSTANCE' ) ), '.' ) padding
   from dual;
column instance clear
column padding  clear
set termout on

accept instance number format 99  default &instance prompt 'Instance Number [&instance]: '
accept sqlid    char   format a13                   prompt 'SQL ID...........&padding : '

-- Display SQL text for the selected ID, both for validation and to roughly mimic the output
-- which DBMS_XPLAN.DISPLAY_CURSOR would have provided.
-- NOTE: The amount of SQL text displayed is limited by the SET LONG value in effect for
--       your session.
column sql_text format a80 word_wrap
select st.sql_fulltext sql_text
   from gv$sql st
   where st.inst_id = &instance
     and st.sql_id  = '&sqlid'
     and rownum     = 1;
column sql_text clear

prompt The following child cursors were found for SQL ID '&sqlid'

-- display a list of valid child cursors for the selected SQL ID
column child_cursors format a80 word_wrap
select listagg( s.child_number, ', ' ) within group ( order by s.child_number ) child_cursors
   from gv$sql s
   where s.inst_id     = &instance
     and s.sql_id      = '&sqlid'
     and s.is_obsolete = 'N';
column child_cursors clear

accept child number format 9999 default 0 prompt 'SQL Child Number............................ [0]: '

-- [G]V$SQL and [G]V$SQL_PLAN_STATISTICS_ALL may include duplicate child cursor numbers
-- for a given SQL statement under 11.2.0.3, due to bug 14585499. We therefore need to
-- obtain the child cursor address, to ensure the DBMS_XPLAN.DISPLAY invocation below
-- doesn't produce duplicate/mangled output.
set termout off
column address noprint new_value address format a16
select rawtohex( s.address ) address
   from gv$sql s
   where s.inst_id      = &instance
     and s.sql_id       = '&sqlid'
     and s.child_number = &child
     and s.is_obsolete  = 'N';
column address clear
set termout on

accept plan_format char format a50 default 'ALL LAST PEEKED_BINDS -PROJECTION' prompt 'XPlan Format [ALL LAST PEEKED_BINDS -PROJECTION]: '
prompt

-- time to make the donuts!!!
select * from table( dbms_xplan.display( 'gv$sql_plan_statistics_all', null, '&plan_format',
                                         q'[inst_id=&instance and sql_id='&sqlid' and child_number=&child and address=hextoraw('&address')]'
                                       )
                   );
