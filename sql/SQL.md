# SQL & PL/SQL scripts

### cursor_xplan.sql

This is intended as a RAC-aware replacement for the DBMS_XPLAN.DISPLAY_CURSOR function, meaning that it does not require you to be connected to the same instance which parsed the cursor of interest.

Usage:
```
@cursor_xplan [sql_id] [sql_child_number] [instance_number] [format]
```
All 4 parameters are optional, and will default to reasonable values. Please note, however, that the default value for *format* is different than what DBMS_XPLAN.DISPLAY_CURSOR uses.
* **sql_id** - Defaults to the previously executed statement.
* **sql_child_number** - Defaults to 0 if *sql_id* was specified, otherwise the last executed statement.
* **instance_number** - Defaults to the current database instance.
* **format** - Defaults to "ALL LAST PEEKED_BINDS -PROJECTION"

Unspecified trailing parameters can simply be omitted. If you want to use the default for a leading parameter, however, you need to use a pair of double-quotes as a placeholder. For example:
```
@cursor_xplan "" "" "" TYPICAL
```
The invoking user will require the following object privileges:

* SELECT on V$SESSION
* SELECT on GV$SQL
* SELECT on GV$SQL_PLAN_STATISTICS_ALL
* EXECUTE on DBMS_XPLAN

### blocker_tree.sql

This displays a RAC-aware, hierarchical tree of blocking/waiting sessions. It's intended as a lightweight aid for troubleshooting issues with blocked sessions, by making it easy to identify the root lockholder(s).

Usage:
```
@blocker_tree
```
The invoking user will require the following object privileges:

* SELECT on GV$SESSION
