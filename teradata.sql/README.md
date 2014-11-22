gen_coll_pi_stats.sql
=====================
generate "collect statistics" on PI column(s).

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
