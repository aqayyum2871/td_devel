gen_get_ora_time_in_date_list.sql
=================================
Check DATE columns, if they contain time portion on Oracle.
This is done by counting distinct time value of each column.
The count of 1 means, that all rows have the same time value.
What is usually 00:00:00 (no time included) but is not guaranteed.

oracle_analyze_date.sql
=======================
Used by oracle_analyze_date.pl

oracle_analyze_date.pl
======================
Analyze every Oracle table in a given schema if the date columns contain time information.
The result is written to a csv file.

Because it can run for a very long time, "commands" to pause or abort the
process by manually creating certain files is possible.

The file oracle_analyze_date.sql is required!

oraunload.sql
=============
Generates unload scripts for Oracle tables. Very simple to execute with SQL*Plus.

A fastload script for Teradata will also be generated.

Does some manipulation of the data, to get it easily unloaded and loaded.
Is limited to line length. But has no other software requirements besides SQL*Plus.

read_dd4Datamodelling.sql
=========================
A while ago, I've created an Excel Document, to generate Teradata DDLs for the creation of tables and views.
The initial intention was the ability to turn an Oracle table to a Teradata table.
By unloading the Oracle Datadictionary to two Excel sheets (Table Info, Column Info).
This SQL generates the data for the Excel from Oracle Dictionary.
