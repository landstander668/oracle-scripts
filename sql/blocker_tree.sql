-- Display a RAC-aware hierarchical tree of blocking/waiting sessions
--
column lock_tree heading "Lock Tree" format a55
column username                      format a40
column child                         format 9999
column pq                            format a4
with sess as (
   select /*+ MATERIALIZE */ s.inst_id, s.sid, s.serial#, s.type, s.username, s.sql_id, s.sql_child_number, s.status, s.program,
          s.blocking_instance, s.blocking_session, s.blocking_session_status
      from gv$session s
),
lk as (
   select s1.blocking_instance || '.' || s1.blocking_session || '.' || s2.serial# blocker, s2.status blocking_status,
          s2.sql_id blocking_sql_id, s2.sql_child_number blocking_child_number, s1.inst_id || '.' || s1.sid || '.' || s1.serial# waiter, s1.status,
          s1.username waiter_username,
          case when s2.type = 'BACKGROUND' then 'System: ' || substr( s2.program, -5, 4 )
               when s2.username is NULL    then 'Unknown: possibly job/scheduler related'
               else s2.username
          end blocker_username,
          s1.sql_id, s1.sql_child_number,
          case when s1.type = 'USER' and regexp_like( s1.program, '^oracle@[^(]+\(P([[:xdigit:]]{3}|[PZ][[:xdigit:]]{2})\)$' ) then substr( s1.program, -5, 4 )
               else NULL
          end waiter_pq,
          case when s2.type = 'USER' and regexp_like( s2.program, '^oracle@[^(]+\(P([[:xdigit:]]{3}|[PZ][[:xdigit:]]{2})\)$' ) then substr( s2.program, -5, 4 )
               else NULL
          end blocker_pq
      from sess s1
         join sess s2 on ( s2.inst_id = s1.blocking_instance and
                           s2.sid     = s1.blocking_session
                         )
      where s1.blocking_instance is not null
        and s1.blocking_session  is not null
        and s1.blocking_session_status = 'VALID'
)
select lpad( '  ', 2*(level-1) ) || t.waiter lock_tree, t.username, t.sql_id, t.child, t.status, t.pq
   from ( select l1.blocker, l1.waiter, l1.waiter_username username, l1.sql_id, l1.sql_child_number child, l1.status, l1.waiter_pq pq
             from lk l1
          union all
          select distinct NULL, l2.blocker, l2.blocker_username, l2.blocking_sql_id, l2.blocking_child_number, l2.blocking_status, l2.blocker_pq
             from lk l2
             where l2.blocker not in ( select l3.waiter from lk l3 )
        ) t
   connect by prior t.waiter = t.blocker
      start with t.blocker is NULL;
