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

### hex_to_\*.sql

This is a series of scripts which take a hexadecimal string as their only parameter, and map it to the corresponding DATE, TIMESTAMP, or TIMESTAMP WITH TIME ZONE value. This can be useful for interpreting values found in tracefiles, as well as the SQL Monitor page of Oracle Enterprise Manager. Results are displayed using the session NLS settings (*nls_date_format*, etc.).

* **hex_to_date.sql** - Map a 14-character hexadecimal value, representing 7 bytes, to DATE. This script can also be use for TIMESTAMP, TIMESTAMP WITH TIME ZONE, and TIMESTAMP WITH LOCAL TIME ZONE values—all of which encode the leading 7 bytes identically—although fractional seconds and any timezone data will naturally be lost.
* **hex_to_timestamp.sql** - Map a 14 or 22 character hexadecimal value, representing 7 or 11 bytes, to TIMESTAMP. This script can also be used for TIMESTAMP WITH **LOCAL** TIME ZONE values, which are encoded in an identical manner (but are normally *displayed* using the client's time zone). The 7-byte version indicates a timestamp with no fractional seconds stored, in which case it's encoded just like a DATE value.
* **hex_to_timestamp_tz.sql** - Map a 26-character hexadecimal value, representing 13 bytes, to TIMESTAMP WITH TIME ZONE.

Usage:
```
@hex_to_date 7877090d01363a
@hex_to_timestamp 7877090d01363a008efd78
@hex_to_timestamp_tz 7877090d05363a008efd78103c
```