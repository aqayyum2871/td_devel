Here are some helpful views to enhance the quality of development with GCFR.

You might need to adapt a bit. At least, database naming.


Check_GCFR_Objects.ddl
======================
Show objects in certain databases, if they are used in any GCFR_Process either as Input/Output or Target!

Check_GCFR_Processes.ddl
========================
Show GCFR processes with information to identify errors in advance, which will lead to an abort in running that process:
* Look if Input/Output or Target object exists or not.
* Check data columns of Input and Output Objects and Target Table if they match.
* Show number of columns in Input and Output Objects and Target Table. Equal numbers do not mean: no problem. The problem will be shown in other TCE columns
* Check if missing column in Input Object is defined as NOT NULL with no default value in Target Table.
* Check if Output Object has keys defined in GCFR_Transform_KeyCol if Process_Type 23, 24 or 25 and if they exist in Target Table.
* Check if Input Object has column GCFR_Delta_Action_Code if Process_Type 24 or 25.
* Check if Target Table has columns start_ts and end_ts if Stream is Intraday.

Important column description:
Column Name | Description
----------- | -----------
INP_Object_Found | Y=The Input Object has been found, N=The Input Object has not been found
OUT_Object_Found | Y=The Output Object has been found, N=The Output Object has not been found
Target_Table_Found | Y=The Target Table has been found, N=The Target Table has not been found
Num_INP_Object_Columns | Number of Data Columns in Input Object
Num_OUT_Object_Columns | Number of Data Columns in Output Object
Num_Target_Table_Columns | Number of Data Columns in Target Table
TCE_OUT_Target_Diff | Transform Column Error: the columnames between Output Object and Target Table do not match
TCE_INP_OUT_Diff | Transform Column Error: the columnames between Input and Output Objects do not match
TCE_in_Target | Transform Column Error: target column is defined as not null and has no default value and is missing in Input/Output Object. Or column exists in Input/Output Object but not in Target Table
TCE_in_Transform_KeyCol | Transform Column Error: no Columns defined as Key in GCFR_Transform_KeyCol or defined Key does not exist as column in Target Table
TCE_in_Process_Type | Transform Column Error: Process_Type is defined as delta, but missing column GCFR_Delta_Action_Code or vice versa
TCE_in_Tech_Columns | Transform Column Error: Too few GCFR technical columns depending on Stream-Cycle-Frequency-Code
Sum_TCE | Summarize all TCE* columns to show errors (easy to order in result set), a number greater then zero will very likely cause an abort in the GCFR process

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
