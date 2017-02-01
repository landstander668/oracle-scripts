-- Display a RAC-aware hierarchical tree of blocking/waiting sessions
--
column lock_tree heading "Lock Tree"
with sess as (
   select /*+ MATERIALIZE */ s.inst_id, s.sid, s.serial#, s.type, s.username, s.program,
          s.blocking_instance, s.blocking_session
      from gv$session s
),
lk as (
   select s1.blocking_instance || '.' || s1.blocking_session blocker,
          s1.inst_id || '.' || s1.sid waiter,
          s1.username waiter_username,
          case when s2.type = 'BACKGROUND' then 'System: ' || regexp_replace( s2.program, '^[^(]*\(([[:alnum:]]+)\)[^)]*$', '\1' )
               when s2.username is NULL    then 'Unknown: possibly job/scheduler related'
               else s2.username
          end blocker_username
      from sess s1
         join sess s2 on ( s2.inst_id = s1.blocking_instance and
                           s2.sid     = s1.blocking_session
                         )
      where s1.blocking_instance is not null
        and s1.blocking_session  is not null
)
select lpad( '  ', 2*(level-1) ) || t.waiter || ' (' || t.username || ')' lock_tree
   from ( select l1.blocker, l1.waiter, l1.waiter_username username
             from lk l1
          union all
          select distinct NULL, l2.blocker, l2.blocker_username
             from lk l2
             where l2.blocker not in ( select l3.waiter from lk l3)
        ) t
   connect by prior t.waiter = t.blocker
      start with t.blocker is NULL;
