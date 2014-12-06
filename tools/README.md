analyze_datafile.pl
===================
Provided is a delimited flat file. This tool analysis the flat file, a proposes the best possible data format for each column, based on the content.
It requires some perl modules for reading CSV files. As well as some initial knowledge of the file format (eg. field delimiter).

This is a very rough tool. The csvkit from onyxfish on github.com can do way more.

count.pl
========
It reads a file and groups every line and counts the number of occurrences of that line.
It's the equivalent of

```sql
select COMPLETE_ROW_FROM_FILE, count(*)
from FILE
group by COMPLETE_ROW_FROM_FILE
order by COMPLETE_ROW_FROM_FILE;
```

csv_check.pl
============
Analyze simple csv file delimitted by pipe (|) and show some statistics per column.

sbitwrapper.c
=============
It is not allowed on Unix/Linux boxes to set the s-bit on an interpreted script file.
This is a compilable program, which executes a (eg. shell) script. On the compiled program, the s-bit can be set.

tptbin
======
TPT (Teradata Parallel Transporter) has an option for a special binary format.
Some tools for handling those data files in this folder.
