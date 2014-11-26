#!/usr/bin/perl

################################################################################
# Copy the table definition including data from one Teradata system to another.
# This is done by "export indicdata" and "fastload"
################################################################################
#
# Some features:
#  -) arguments only from command line (no script has to be changed)
#  -) table and column comments are created
#     Because of max linesize of 254 in bteq, the last bytes could be cutted.
#  -) secondary indices are created after fastload
#
################################################################################
# Requirements:
#  -) VarSubst (included with SLJM)
#  -) TTU (bteq, fastload)
################################################################################
# Limitations:
#  -) Datatypes (the most common are supported)
################################################################################

use Getopt::Long;

################################################################################
# presets
################################################################################
$args = $#ARGV;
$maxTabNameLen = 30;
$sessions = 9;
$whereclause = "";
$drop=0;
$delim="|";
################################################################################

GetOptions (
	'slogon=s' => \$slogon,
	'dlogon=s' => \$dlogon,
	'sdb=s' => \$db_btq,
	'ddb=s' => \$db_fl,
	'table=s' => \$table,
	'newtable=s' => \$newtable,
	'help' => \$help,
	'where=s' => \$where,
	'drop!' => \$drop
	);

if ($help || $args < 0) {
	print "Copy specified table from one system to another!\n";
	#print "ATTENTION: Because of max linesize of 254 in bteq, long comments could be trimmed.\n";
	print "IMPORTANT: The logon files have to contain the TDP, the username and password.\n";
	print "usage: $0 \\\n";
	print "          --slogon=<logonfile for source> \\        # must be a file for security reason\n";
	print "          [--dlogon=<logonfile for destination>] \\ # must be a file for security reason\n";
	print "          --sdb=<databasename for source> \\\n";
	print "          [--ddb=<databasename for destination>] \\\n";
	print "          --table=<tablename to be transferred> \\\n";
	print "          [--newtable=<new tablename>] \\\n";
	print "          [--where=<where clause without the word \"where\">]\n";
	print "          [--drop/nodrop]  # drop target table before fastload (must be empty; no usi/nusi) (default is drop)\n";
	exit;
}

unless ($slogon) {
	print STDERR "Please specify a logonfile for source with \"--slogon=<logonfile>\"!\n";
	print STDERR "Get help with \"$0 --help\"\n";
	exit 1;
}
$ENV{LOGON}=$slogon;
open (CONTROL, 'echo \${LOGON} | VarSubst |');
$sdblogon=<CONTROL>;
close (CONTROL);
$sdblogon =~ s/ /,/;

unless ($dlogon) {
	$dlogon = $slogon;
}
$ENV{LOGON}=$dlogon;
open (CONTROL, 'echo \${LOGON} | VarSubst |');
$ddblogon=<CONTROL>;
close (CONTROL);
$ddblogon =~ s/ /,/;

unless ($db_btq) {
	print STDERR "Please specify the source database \"--sdb=<databasename>\"!\n";
	print STDERR "Get help with \"$0 --help\"\n";
	exit 1;
}
unless ($db_fl) {
	$db_fl=$db_btq;
}
unless ($table) {
	print STDERR "Please specify the table to be copied \"--table=<tablename>\"!\n";
	print STDERR "Get help with \"$0 --help\"\n";
	exit 1;
}

unless (-s $slogon) {
	print STDERR "Source-Logon (bteq) is no correct file!\n";
	print STDERR "Get help with \"$0 --help\"\n";
	exit 1;
} else {
	open(SRC, "<$slogon") || die "Cannot open slogon-File!\n";
	chomp($logon_btq = <SRC>);
	close(SRC);
}

unless (-s $dlogon) {
	print STDERR "Destination-Logon (fastload) is no correct file!\n";
	exit 1;
} else {
	open(DST, "<$dlogon") || die "Cannot open dlogon-File!\n";
	chomp($logon_fl = <DST>);
	close(DST);
}

if ($where) {
	$whereclause = "WHERE " . $where unless ($where =~ /^ *where/i);
}

unless ($newtable) {
	$newtable = $table;
}


##########################################
## do not modify lines below
##########################################

unlink "pipe_$newtable";
unless (-p "pipe_$newtable") {
	system('mkfifo', "pipe_$newtable") && die "can't mkfifo pipeline: $!";
}


$str_btq_1="
logon $sdblogon;
.set width 65531;
.set echoreq off;
database $db_btq;
select \'u>'||trim(both from ColumnName)||\' \'||trim(both from CharType)||\' \'||
  (case when ColumnType = \'DA\' then 10
       when ColumnType = \'I\' then 12
       when ColumnType = \'I1\' then 4
       when ColumnType = \'I2\' then 6
       when ColumnType = \'I4\' then 12
       when ColumnType = \'I8\' then 38
       when ColumnType in (\'D\', \'F\') then 38
       when ColumnType in (\'CF\', \'CV\') then cast(ColumnLength as integer)
       when ColumnType = \'TS\' then 26
       else -1
  end)
from dbc.columns
where databasename = \'$db_btq\'
and tablename = \'$table\'
order by ColumnID;
show table $table;
select \'c>tx \'||CommentString
from dbc.tables
where databasename = \'$db_btq\'
and tablename = \'$table\'
and CommentString is not null;
select \'c>c\'||trim(both from ColumnName)||\' \'||CommentString
from dbc.columns
where databasename = \'$db_btq\'
and tablename = \'$table\'
and CommentString is not null;
select \'s>i\'||trim(both from cast(indexnumber as varchar(20)))||\' \'||trim(both from columnname) (title \'\')
from dbc.indices
where databasename = \'$db_btq\'
and tablename = \'$table\'
order by indexnumber, columnname;
select \'s>c\'||trim(both from a.columnname) (title \'\')
from dbc.columnstats a
join dbc.tables b
on a.databasename = b.databasename
and a.tablename = b.tablename
where b.tablekind = 'T'
  and a.fieldstatistics is not null
  and b.databasename = \'$db_btq\'
  and b.tablename = \'$table\'
order by a.columnname;
select \'s>C\'||trim(both from cast(statisticsid as varchar(20)))||\' \'||trim(both from columnname) (title \'\')
from dbc.MultiColumnStats
where databasename = \'$db_btq\'
and tablename = \'$table\'
order by statisticsid, columnname;
.quit;
";

$etab = substr($newtable, 0, 26);

$str_fl_1 = "
tenacity 2;
sleep 1;
logon $ddblogon;
database $db_fl;
drop table ${etab}_et1;
drop table ${etab}_et2;
";

if ($drop == 0) {
	$str_fl_1 .= "drop table ${newtable};\n";
}

$str_btq_3="
logon \\\${LOGON};
.set width 65531;
database $db_fl;
";

$_logging = 0;
$_create_index = '';
$_collect_statistics = '';

$ENV{LOGON}=$slogon;
open (CONTROL, "echo \"$str_btq_1\" | VarSubst | bteq 2>&1 |");

$statidx = 0;
$statidxcnt = 0;
$unicode = 0;
undef(@columns);
undef(%collen);

while ( $_line = <CONTROL> ) {

	## uncomment for testing
	## print $_logging . " : " . $_line;

	($_line =~ /\*\*\* Failure 3802/) && die "No such Database !?\n";
	($_line =~ /\*\*\* Failure 3807/) && die "No such Table !?\n";
	($_line =~ /Logon failed\!/)      && die "Logon failed !!\n";
	($_line =~ /Invalid logon\!/)     && die "Logon invalid !!\n";

	if ($_logging == 0 && $_line =~ /^u\>(\S+)\s+(\S+)\s+(\S+)/) {
	  $colname = $1;
	  $chartype = $2;
	  $len = $3;
	  if ($len == -1) {
	    die "Datatype not supported!\n";
	  }
	  push(@columns, $colname);
	  if ($chartype == 2) {
	    $unicode = "-c UTF8";
	  }
	  $collen{$colname} = $len;
	}

	if ($_line =~ /(^CREATE \w*SET TABLE )\w+\.(\S*),*(\S*)/) {
		if ($3) {
			$_line = $1 . " $newtable ";
		} else {
			$_line = $1 . " $newtable ," . $3;
		}
		$_logging = 1;
	}

	if ($_logging == 2 && $_line =~ /^(unique index|index) (\S+)\;*/i) {

		$_ind=$1;
		$_nam=$2;

		if ($_nam =~ /\;/) {
			$_logging = 0;
		} else {
			$_logging = 10;
		}
		$_create_index .= "CREATE $_ind $_nam";
		$_create_index =~ s/\;//g;

		if ($_line =~ /\)/) {
			$_create_index .= " ON $newtable;\n";
		}
		next;
	}

	if ($_logging >= 1 && $_logging <= 10) {

		# Aktuelle Zeile wird an den String angehängt.
		$_create_table .= $_line ;
		$_create_table =~ s/;$//g;

		# Erkenne, ob die Primary Key Definition kommt
		if ($_line =~ /PRIMARY INDEX/) {
			$_logging = 2;
		}

		if ($_line =~ /PARTITION BY/) {
			$_logging = 3;
		}

		if (($_line =~ /;$/) && ($_logging >= 2)) {
			$_logging = 0;
		}

		if (($_line =~ /\)/) && ($_logging > 2)) {
			$_logging = 0;
		}

	}

	if ($_logging >= 10 && $_logging < 20) {

		# Aktuelle Zeile wird an den String angehängt.
		$_create_index .= $_line ;

		if (($_line =~ /\)/) && ($_logging == 10)) {
			chomp($_create_index);
			$_create_index =~ s/;.*$//;
			$_create_index .= " ON $newtable;\n";
			$_logging = 0;
		}

	}

	if ($_logging == 0 && $_line =~ /^c\>(.)([^ ]*?) ([^\n]*)/i) {

		$a = $1;
		$b = $2;
		$x = $3;
		$x =~ s/\'/\'\'/g;

		if ($a eq "t") {
			$_create_index .= "COMMENT ON TABLE $newtable IS \'" . $x . "\';\n";
		} elsif ($a eq "c") {
			$_create_index .= "COMMENT ON COLUMN $newtable.$b IS \'" . $x . "\';\n";
		}

	}

	#
	# Statistics starting here
	#
	if ($_logging == 21 && $_line !~ /^s\>i/) {

		unless (defined($statidx{$stati})) {
			$_collect_statistics .= "COLLECT STATISTICS ON $newtable INDEX ($stati);\n";
			$statidx{$stati} = 1;
		}

		$_logging = 0;

	}

	if ($_logging == 22 && $_line !~ /^s\>C/) {

		unless (defined($statidx{$stati})) {
			$_collect_statistics .= "COLLECT STATISTICS ON $newtable COLUMN ($stati);\n";
			$statidx{$stati} = 1;
		}

		$_logging = 0;

	}

	if ($_logging == 0 && $_line =~ /^s\>c([^\n]*)/) {

		$a = $1;

		unless (defined($statidx{$a})) {
			$_collect_statistics .= "COLLECT STATISTICS ON $newtable COLUMN ($a);\n";
			$statidx{$a} = 1;
		}

		next;
	}

	if ($_logging == 0 && $_line =~ /^s\>i([^ ]*?) ([^\n]*)/) {

		$stati = $2;      # ColumnName
		$statidx = $1;    # IndexID

		$_logging = 21;

		next;
	}

	if ($_logging == 21 && $_line =~ /^s\>i([^ ]*?) ([^\n]*)/) {

		$a = $1;  # IndexID
		$b = $2;  # ColumnName

		if ($statidx != $a) {
			unless (defined($statidx{$stati})) {
				$_collect_statistics .= "COLLECT STATISTICS ON $newtable INDEX ($stati);\n";
				$statidx{$stati} = 1;
				$stati = $b;
			}
			$statidx = $a;
		} else {
			$stati .= ",$b";
		}

		next;
	}

	if ($_logging == 0 && $_line =~ /^s\>C([^ ]*?) ([^\n]*)/) {

		$stati = $2;      # ColumnName
		$statidx = $1;    # IndexID

		$_logging = 22;

		next;
	}

	if ($_logging == 22 && $_line =~ /^s\>C([^ ]*?) ([^\n]*)/) {

		$a = $1;  # IndexID
		$b = $2;  # ColumnName

		if ($statidx != $a) {
			unless (defined($statidx{$stati})) {
				$_collect_statistics .= "COLLECT STATISTICS ON $newtable COLUMN ($stati);\n";
				$statidx{$stati} = 1;
				$stati = $b;
			}
			$statidx = $a;
		} else {
			$stati .= ",$b";
		}

		next;
	}

}
close CONTROL;

if ($_logging == 21) {
	unless (defined($statidx{$stati})) {
		$_collect_statistics .= "COLLECT STATISTICS ON $newtable INDEX ($stati);\n";
	}
} elsif ($_logging == 22) {
	unless (defined($statidx{$stati})) {
		$_collect_statistics .= "COLLECT STATISTICS ON $newtable COLUMN ($stati);\n";
	}
}

$_create_table .= ";\n";

## uncomment for testing
## print $str_btq_1;
## print $str_btq_3;
## print $_create_table;
## print $_create_index;
## print $_collect_statistics;
## exit;

#
# Starte hier mit einem fork den Export und Import parallel.
#
unless ($pid_exp = fork) {

	#
	# Jetzt bin ich im Child process
	#

  $allcol=0;
  $str_btq_2 = "logon $sdblogon;\n";
  $str_btq_2 .= ".set width 65531;\n";
  $str_btq_2 .= "database $db_btq;\n";
  $str_btq_2 .= ".export report file = pipe_$newtable , close\n";
  foreach $col (@columns) {
    if ($allcol == 0) {
      $str_btq_2 .= "select  (trim(trailing from (coalesce(cast($col as varchar($collen{$col})), \'\'))))\n";
    } else {
      $str_btq_2 .= "   ||\'$delim\'||(trim(trailing from (coalesce(cast($col as varchar($collen{$col})), \'\'))))\n";
    }
    $allcol=1;
  }
  $str_btq_2 .= "(title '')\nfrom $table\n";
  $str_btq_2 .= "$whereclause;\n";
  $str_btq_2 .= ".quit\n";

	$ENV{LOGON}=$slogon;
	open (CONTROL, "echo \"$str_btq_2\" | VarSubst | bteq $unicode 2>&1 |");
	while ( <CONTROL> ) {
		print "-> $_";
	}
	close(CONTROL);

	exit;
}

#
# Hier läuft der Parent weiter
#
$str_fl_2 = "begin loading $newtable\n";
$str_fl_2 .= "errorfiles ${etab}_et1, ${etab}_et2;\n";
$str_fl_2 .= '.set record vartext \"' . $delim . '\"' . ";\n";
$str_fl_2 .= "define\n";
$deli=" ";
foreach $col (@columns) {
  $str_fl_2 .= "   $deli$col          (varchar($collen{$col}))\n";
  $deli=",";
}
#$str_fl_2 .= "   ,CRLF          (varchar(1))\n";
$str_fl_2 .= "file = pipe_$newtable;\n";
$str_fl_2 .= "insert $newtable (\n";
$deli=" ";
foreach $col (@columns) {
  $str_fl_2 .= "   $deli$col\n";
  $deli=",";
}
$str_fl_2 .= ") values (\n";
$deli=" ";
foreach $col (@columns) {
  $str_fl_2 .= "   $deli:$col\n";
  $deli=",";
}
$str_fl_2 .= ");\n";
$str_fl_2 .= "end loading;\n";
$str_fl_2 .= ".quit;\n";

if ($drop == 1) {
  $str_fl = $str_fl_1 . $str_fl_2 ;
} else {
  $str_fl = $str_fl_1 . $_create_table . $str_fl_2 ;
}

$ENV{LOGON}=$dlogon;
open (CONTROL, "echo \"$str_fl\" | VarSubst | fastload $unicode 2>&1 |");
while ( <CONTROL> ) {
	print "<- $_";
}
unlink "pipe_$newtable";

# And now, create indexes
if ($_create_index) {
	$str_btq_3 .= $_create_index . $_collect_statistics . ".quit\n";
	$ENV{LOGON}=$dlogon;
	open (CONTROL, "echo \"$str_btq_3\" | VarSubst | bteq 2>&1 |");
	while ( <CONTROL> ) {
		print "<- $_";
	}
}

do {
	sleep 2;
} until (waitpid($pid_exp, WNOHANG));

#print $_create_index;

exit;
