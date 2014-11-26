#!/usr/bin/perl -w

#############################################################################
# (c) 2012 by Teradata Germany GesmbH, Andreas Wenzel
#
# Perl program to connect to a Oracle Database and analyze columns with date
# data type, and deliver analysis as CSV file for MS Excel.
#
# This is accomplished by executing the following steps:
#  1. Connect to Oracle with SQL*Plus and generate a file with all the
#     Select statements for all date columns owned by a particular schema.
#     Disconnect from Oracle, again.
#  2. Connect to Oracle with SQL*Plus and execute the previously generated
#     SQL file and spooling the result into a text file.
#     The following commands from "outside" of this programs are allowed:
#     1. Create a file called "PAUSE" in current directory will pause the
#        execution before queriing the next table. Remove to release.
#     2. Create a file called "BREAK" in current directory will abort
#        the process controlled before queriing the next table. This file
#        will be removed on start of this program.
#        Every table, the database is working on, is written down to the
#        file called "NEXT" in current directory. If this file exists
#        while invoking this program, it is considered as resume, and the
#        program will start queriing the tables with the one in this file.
#     Disconnect from Oracle, again.
#  3. Parse the output of the second step, and produce a CSV file with one
#     record for one column.
#
# The file "oracle_analyze_date.sql" is required for dynamic SQL.
# If the count for one column is higher than 1, then it is considered as
# column with time portion.
# The first column of the result CSV file consists of the Date/Time
# indicator: "DT" = Date and Time, "DO" = Date only
#
# The goal is to utilize the database as least as possible.
# So, if the table is partitioned, then a sample(10) will be appended to the
# query. If not, there is a full table scan. This decision is made in script
# oracle_analyze_date.sql
# Though, 10 percent of a really hugh table can still run for long on Oracle.
#
# To hide database credentials, the following three environment variables are
# understood:
#   ORA_USR = Username to connect to Oracle
#   ORA_PWD = Password to connect to Oracle
#   ORA_ADR = Oracle Alias or database connect credentials to connect to
# No database credentials are shown as argument or in process list.
#############################################################################

use Time::Local;

$|++;

$data = 0;
$sep = ";";
$log_username = "system";
$log_passwd = "systemmanager";
$log_address = "vm1310";
$listfile = "tmp_oracle_analyze_date.sql";
$breakfile = "BREAK";
$pausefile = "PAUSE";
$stepfile = "NEXT";
$resultfile = "tmp_oracle_analyze_date_result.txt";
$resultcsvfile = "oracle_analyze_date_result.csv";

my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst);

unlink $breakfile if (-f $breakfile);

if (!defined($ARGV[0]) || $ARGV[0] eq "") {
	$db = "%";
} else {
	$db = $ARGV[0];
}

$log_username = $ENV{ORA_USR} if (defined($ENV{ORA_USR}));
$log_passwd = $ENV{ORA_PWD} if (defined($ENV{ORA_PWD}));
$log_address = $ENV{ORA_ADR} if (defined($ENV{ORA_ADR}));

unlink $listfile if (-f $listfile);

(-f "oracle_analyze_date.sql") or die "Error while opening oracle_analyze_date.sql: $!\n";
open (SQLPLUS1, "| sqlplus -s /nolog >/dev/null") or die "Error while starting sqlplus1: $!\n";

print SQLPLUS1 "conn $log_username/$log_passwd\@$log_address;\n";
print SQLPLUS1 "whenever sqlerror exit failure rollback\n";
print SQLPLUS1 "whenever oserror exit failure rollback\n";
print SQLPLUS1 "set term off echo off verify off head off\n";
print SQLPLUS1 "select to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') from dual;\n";
($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - Start generate columns list\n", $year+1900, $mon+1, $day, $hour, $min, $sec );
print SQLPLUS1 "\@oracle_analyze_date.sql $db $listfile\n";
($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - End generate columns list\n", $year+1900, $mon+1, $day, $hour, $min, $sec );
print SQLPLUS1 "exit\n";
close (SQLPLUS1);

open (SQLPLUS2, "| sqlplus -s /nolog >/dev/null") or die "Error while starting sqlplus2: $!\n";
($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - Start collect column counts\n", $year+1900, $mon+1, $day, $hour, $min, $sec );
print SQLPLUS2 "conn $log_username/$log_passwd\@$log_address;\n";
print SQLPLUS2 "whenever sqlerror exit failure rollback\n";
print SQLPLUS2 "whenever oserror exit failure rollback\n";
print SQLPLUS2 "set term off echo off verify off head off\n";
print SQLPLUS2 "select to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss') from dual;\n";

open (SQL1, "<$listfile") or die "Temp file empty. No Tables to analyze? $!\n";

if (-f $stepfile) {
	open (STEP, "<$stepfile") or die "Cannot open stepfile $stepfile: $!\n";
	$next = <STEP>;
	chomp($next);
	($ldb, $ltab) = split(/\t/, $next);
	close (STEP);
	($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - Resume encountered. Starting with $ldb.$ltab\n", $year+1900, $mon+1, $day, $hour, $min, $sec );
}

$block = 0;
$dorun = 0;

foreach $line (<SQL1>) {
	chomp($line);
	$line =~ s/\r//g;
	if ($line =~ /^\-\-\#\#\-\-\#\#\-\-\#\#\tEND$/) {
		unlink $stepfile;
		$dorun = 1;
	} elsif (defined($ldb) && defined($ltab) && $line =~ /^\-\-\#\#\-\-\#\#\-\-\#\#\t(.+)\t(.+)/) {
		# only for resume
		if ($1 eq $ldb && $2 eq $ltab) {
			$block = 2;
			undef($ldb);
			undef($ltab);
		} else {
			$block = 1;
		}
	} elsif (-f $breakfile && $line =~ /^\-\-\#\#\-\-\#\#\-\-\#\#\t(.+)\t(.+)/) {
		# controlled abort
		$db = $1;
		$tab = $2;
		($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - Break file encountered. Stopping at $db.$tab\n", $year+1900, $mon+1, $day, $hour, $min, $sec );
		open (NEXT, ">$stepfile") or die "Cannot write to stepfile $stepfile: $!\n";
		print NEXT "$db\t$tab\n";
		close (NEXT);
		last;
	} elsif (-f $pausefile && $line =~ /^\-\-\#\#\-\-\#\#\-\-\#\#\t(.+)\t(.+)/) {
		($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - Pause file encountered. Waiting 60 seconds\n", $year+1900, $mon+1, $day, $hour, $min, $sec );
		sleep 60;
	} elsif ($line =~ /^\-\-\#\#\-\-\#\#\-\-\#\#\t(.+)\t(.+)/) {
		$block = 2;
		$db = $1;
		$tab = $2;
		open (NEXT, ">$stepfile") or die "Cannot write to stepfile $stepfile: $!\n";
		print NEXT "$db\t$tab\n";
		close (NEXT);
	} elsif ($block == 0 || $block == 2) {
		print SQLPLUS2 "$line\n";
	}
}

print SQLPLUS2 "select to_char(sysdate, 'yyyy-mm-dd hh24:mi:ss')||': End collect counts for all columns' from dual;\n";
close (SQLPLUS2);

($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - End collect column counts\n", $year+1900, $mon+1, $day, $hour, $min, $sec );

unlink $stepfile if ($dorun == 1);

exit if ($dorun == 0);

($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - Start prepare result for CSV\n", $year+1900, $mon+1, $day, $hour, $min, $sec );

print "Ind DO/DT${sep}Database Name${sep}Table Name${sep}Total Rows${sep}Column Name${sep}# Rows w/ Time\n";

open (RESULT, "<$resultfile") or die "Cannot open result file $resultfile: $!\n";
open (RESULTCSV, ">$resultcsvfile") or die "Cannot create result csv file $resultfile: $!\n";

foreach $line (<RESULT>) {
	chomp($line);
	
	next if ($line =~ /^$/);
	next if ($line =~ /^-------------/);

	if ($line =~ /^DATABASE_NAME/) {
		@cols = split(/\s+/, $line);
		$data = 1;
	} elsif ($data == 1) {
		@vals = split(/\s+/, $line);
		for ($i = 3; $i <= $#vals; $i++) {
			$cols[$i] =~ s/^COL\_//;
			if ($vals[$i] > 1) {
				print (RESULTCSV "DT" . $sep . $vals[0] . $sep . $vals[1] . $sep . $vals[2] . $sep . $cols[$i] . $sep . $vals[$i] . "\n");
				print ("DT" . $sep . $vals[0] . $sep . $vals[1] . $sep . $vals[2] . $sep . $cols[$i] . $sep . $vals[$i] . "\n");
			} else {
				print (RESULTCSV "DO" . $sep . $vals[0] . $sep . $vals[1] . $sep . $vals[2] . $sep . $cols[$i] . $sep . $vals[$i] . "\n");
				print ("DO" . $sep . $vals[0] . $sep . $vals[1] . $sep . $vals[2] . $sep . $cols[$i] . $sep . $vals[$i] . "\n");
			}
		}
		$data = 0;
	}
}

close (RESULT);
close (RESULTCSV);

($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
warn sprintf ( "%04d-%02d-%02d %02d:%02d:%02d - End prepare result for CSV\n", $year+1900, $mon+1, $day, $hour, $min, $sec );
