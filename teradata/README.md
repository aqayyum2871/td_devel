cp_tab.pl
=========
Copy a table from one Teradata System to another using bteq/fastload.

Be aware, that program hasn't been used for a long time, try on uncritical data, first.
Also check the required data types, which are probably a current limitation.

gen_coll_pi_stats.sql
=====================
generate "collect statistics" on PI column(s).

gen_tpt.sql
===========
SQL file to generate TPT script. Don't use directly. Use gen_tpts.sql instead.

gen_tpts.sql
============
Mass TPT script generator based on tables in a list of databases. Modify this file to meet your requirements.

Fileformat is limitted to
* Format = Binary
* Indicator = Y

load.sh
=======
Load single table to teradata. TPT scripts must have been generated in advance (gen_tpts.sql).
Data is provided by some tool (you need to specify) and passed to a named pipe. TPT will read from that named pipe.

load_all.sh
===========
Purpose is to mass unload tables from (eg. Oracle) and load it to Teradata.
Use this to mass process the tables based on the available TPT scripts.

load_parallel.sh
================
Tool to run the tables in parallel by a given degree of parallelism.

Because it can run for a very long time, "commands" to pause or abort the
process by manually creating certain files is possible.

MM_Element_Import_Structure.sql
===============================
SQL to retrieve column information in format to import it to Teradata Mapping Manager.

Mapping Manager does not import it! And I don't know why. Grrr

read_dd4Datamodelling.sql
=========================
A while ago, I've created an Excel Document, to generate Teradata DDLs for the creation of tables and views.
The initial intention was the ability to turn an Oracle table to a Teradata table.
By unloading the Oracle Datadictionary to two Excel sheets (Table Info, Column Info).
This SQL generates the data for the Excel from Teradata Dictionary.

show_skew_factor.sql
====================
Simple display of skey factor per table in certain database

sp_gen_121_views.sql
====================
Create stored procedure to create 1:1 views based on tables in a certain database (with lock row for access)
