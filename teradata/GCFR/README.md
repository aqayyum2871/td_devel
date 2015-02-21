Here are some helpful views to enhance the quality of development with GCFR.

You might need to adapt a bit. At least, database naming.


Check_GCFR_Objects.ddl
======================
Show objects in certain databases, if they are used in any GCFR_Process either as Input/Output or Target!

Check_GCFR_Processes.ddl
========================
Show GCFR processes an look if Input/Output or Target object exists or not!

Check_GCFR_TargetPopulation.ddl
===============================
Show target tables and show number of processes populating it!

Check_Transform_KeyCol.ddl
==========================
For all process_types of 23 and 24, count the number of key columns.
If the count is 0, then this process will fail.

Check_Transform_Process_Type.ddl
================================
Compares the defined process_type in GCFR_Process with the definition of the input view.
Process_type 23 does not allow to have the column "GCFR_Delta_Action_Code", whilst process_type 24 requires this column to be runable.

Gen_GCFR_Calls.ddl
==================
This view generates a list of process executions for GCFR_Process table. Either to use in SLJM (with variables) or directly in SQL Assistant.
If using in SQL Assistant, the database names might need to get changed to the correct environment database name.

Gen_GCFR_Comments.ddl
=====================
Generates simple "comment on" commands for input and output views from GCFR_Process table, to put some information onto the views.

Gen_SLJM_Job.ddl
================
After ordering the output by column "Absolute_Order", the execution sequence for SLJM - including parallel processing - is generated.
The output for one Stream can build the complete job file for SLJM. Therefore, the steps for one target table are set to run sequentially,
while different target tables to run in parallel (if they don't have any dependencies). Use the variable SLJMPROCLIMIT to limit the parallel
running processes per job.
