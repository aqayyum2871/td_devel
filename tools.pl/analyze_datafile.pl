#!/bin/perl -w

#
# Analyze datafile and propose column definition based on content
#

use Getopt::Long;
use Text::CSV_XS;

$inputfile = "";
$header = 0;
$delimiter = "\t";
$minvarchar = 16;
$maxchar = 15;
$maxnumvals = 50;       # after $limitrows4val track only number of occurrancies for the most occurring $maxnumvals values
$limitrows4val = 10000; # this prevents columns with unique values to consume a lot of memory (in building a long hash)
$help = 0;

GetOptions(
	"csvdoc=s" => \$inputfile
	,"delimiter=s" => \$delimiter
	,"header" => \$header
	,"help" => \$help
	,"maxchar=s" => \$maxchar
	,"minvarchar=s" => \$minvarchar
	,"maxnumvals=s" => \$maxnumvals
);

die "Definition of minvarchar must be greater than maxchar!\n" if ($minvarchar <= $maxchar);

%csvattr = (
	binary => 1
	,eol => $\
	,sep_char => $delimiter
	,allow_whitespace => 1
	,quote_char => '"'
	,escape_char => '"'
	,allow_loose_escapes => 1
	,blank_is_undef => 1
	,empty_is_undef => 1
);

sub Compress {
	my ($myrow, $mycol, $myval) = @_;
	if ($myrow <= $limitrows4val) {
		if (exists($myfieldval[$mycol]{$myval})) {
			$myfieldval[$mycol]{$myval}++;
		} else {
			$myfieldval[$mycol]{$myval} = 1;
		}
	}
	if ($myrow == $limitrows4val) {
		my $i = 0;
		foreach $ke (sort { $myfieldval[$mycol]{$b} <=> $myfieldval[$mycol]{$a} } keys %{$myfieldval[$mycol]}) {
			delete($myfieldval[$mycol]{$ke}) if ($i >= $maxnumvals);
			$i++;
		}
	} elsif ($myrow > $limitrows4val) {
		$myfieldval[$mycol]{$myval}++ if (delete($myfieldval[$mycol]{$myval}));
	}
}

my $csv = Text::CSV_XS->new (\%csvattr);
open my $io, "<", $inputfile or die "Cannot open CSV document \"$inputfile\": $!\n";

#open(INFILE, $inputfile) or die "Cannot read from $inputfile";

$lineno = 0;
$numfields = 0;
$myheaderfields = 0;

while (my $row = $csv->getline ($io)) {

	$lineno++;

	my @myline = @$row;

	$numfields = $#myline if ($numfields < $#myline);

	if ($header == 1 && $lineno == 1) {
		@myheader = @$row;
		next;
	} elsif ($header == 0 && $myheaderfields < $numfields) {
		for (my $i = $myheaderfields; $i <= $numfields; $i++) {
			push(@myheader, "");
		}
		$myheaderfields = $numfields;
	}

	for (my $i = 0; $i <= $numfields; $i++) {

		if (defined($myline[$i]) && $myline[$i] ne "") {

			Compress($lineno, $i, $myline[$i]);

			if (defined($myfieldlen[$i]) && $myfieldlen[$i] != 0) {
				$myfieldlen[$i] = length($myline[$i]) if ($myfieldlen[$i] < length($myline[$i]));
			} else {
				$myfieldlen[$i] = length($myline[$i]);
			}

			# Check content of one field of one row
			if ($myline[$i] =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\.){0,1}(\d{1,6}){0,1}$/) {
				# Timestamp, Timestamp(0-6)
				$a = $8;

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = $myline[$i];
					$myfieldmaxval[$i] = $myline[$i];
					$myfieldmintype[$i] = "TS";
					$myfieldmaxtype[$i] = "TS";
					$myfieldtype[$i] = "TS";
					if (defined($a)) {
						$y = length($a);
						$myfieldnumfracdigit[$i] = $y;
					} else {
						$myfieldnumfracdigit[$i] = 0;
					}
					$myfieldnumprecdigit[$i] = 0;

				} else {

					$myfieldminval[$i] = $myline[$i] if ($myfieldminval[$i] gt $myline[$i]);
					$myfieldmaxval[$i] = $myline[$i] if ($myfieldmaxval[$i] lt $myline[$i]);

					if (defined($a)) {
						$y = length($a);
					} else {
						$y = 0;
					}
					$myfieldnumfracdigit[$i] = $y if ($myfieldnumfracdigit[$i] < $y || (!defined($myfieldnumfracdigit[$i])));

					if ($myfieldtype[$i] ne "TS") {
						$myfieldtype[$i] = "C";
					}
				}

			} elsif ($myline[$i] =~ /^\d{4}-\d{2}-\d{2}$/) {
				# Date

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = $myline[$i];
					$myfieldmaxval[$i] = $myline[$i];
					$myfieldmintype[$i] = "DA";
					$myfieldmaxtype[$i] = "DA";
					$myfieldtype[$i] = "DA";
					$myfieldnumfracdigit[$i] = 0;
					$myfieldnumprecdigit[$i] = 0;

				} else {

					if ($myfieldmintype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldminval[$i] = $myline[$i] if ($myfieldminval[$i] gt $myline[$i]);
					}
					if ($myfieldmaxtype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldmaxval[$i] = $myline[$i] if ($myfieldmaxval[$i] lt $myline[$i]);
					}

					if ($myfieldtype[$i] ne "DA") {
						$myfieldtype[$i] = "C";
					}
				}

			} elsif ($myline[$i] =~ /^\d{2}:\d{2}:\d{2}\.?(\d{0,6})$/) {
				# Time, Time(0 - 6)
				$a = $1;

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = $myline[$i];
					$myfieldmaxval[$i] = $myline[$i];
					$myfieldmintype[$i] = "T";
					$myfieldmaxtype[$i] = "T";
					$myfieldtype[$i] = "T";
					if (defined($a)) {
						$y = length($a);
						$myfieldnumfracdigit[$i] = $y;
					} else {
						$myfieldnumfracdigit[$i] = 0;
					}
					$myfieldnumprecdigit[$i] = 0;

				} else {

					if ($myfieldmintype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldminval[$i] = $myline[$i] if ($myfieldminval[$i] gt $myline[$i]);
					}
					if ($myfieldmaxtype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldmaxval[$i] = $myline[$i] if ($myfieldmaxval[$i] lt $myline[$i]);
					}

					if ($myfieldtype[$i] ne "T") {
						$myfieldtype[$i] = "C";
					}

				}

			} elsif ($myline[$i] =~ /^\".*\"$/) {
				# Character with quotes

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = $myline[$i];
					$myfieldmaxval[$i] = $myline[$i];
					$myfieldmintype[$i] = "C";
					$myfieldmaxtype[$i] = "C";
					$myfieldtype[$i] = "C";
					$myfieldnumfracdigit[$i] = 0;
					$myfieldnumprecdigit[$i] = 0;

				} else {

					$myfieldtype[$i] = "C";
					$myfieldminval[$i] = $myline[$i] if ($myfieldminval[$i] gt $myline[$i]);
					$myfieldmaxval[$i] = $myline[$i] if ($myfieldmaxval[$i] lt $myline[$i]);

				}

			} elsif ($myline[$i] =~ /^\.$/) {
				# just a dot in field

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = 0.0;
					$myfieldmaxval[$i] = 0.0;
					$myfieldmintype[$i] = "I";
					$myfieldmaxtype[$i] = "I";
					$myfieldtype[$i] = "I1";
					$myfieldnumfracdigit[$i] = 0;
					$myfieldnumprecdigit[$i] = 1;

				} else {

					if ($myfieldmintype[$i] =~ /^(D|I[1248])$/) {
						$myfieldminval[$i] = 0.0 if ($myfieldminval[$i] > 0);
					} else {
						$myfieldminval[$i] = $myline[$i] if ($myfieldminval[$i] gt $myline[$i]);
						$myfieldmintype[$i] = "C";
					}
					if ($myfieldmaxtype[$i] =~ /^(D|I[1248])$/) {
						$myfieldmaxval[$i] = 0.0 if ($myfieldmaxval[$i] < 0);
					} else {
						$myfieldmaxval[$i] = $myline[$i] if ($myfieldmaxval[$i] lt $myline[$i]);
						$myfieldmaxtype[$i] = "C";
					}
					if ($myfieldtype[$i] =~ /^(DA|TS|T)$/) {
						$myfieldtype[$i] = "C";
					}

				}

			} elsif ($myline[$i] =~ /^(\-|\+){0,1}\d+$/) {
				# Integer?

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = $myline[$i];
					$myfieldmaxval[$i] = $myline[$i];
					$myfieldmintype[$i] = "I";
					$myfieldmaxtype[$i] = "I";
					$myfieldnumfracdigit[$i] = 0;
					$myfieldnumprecdigit[$i] = 0;
					# Value is integer, evaluate the proper size
					if ($myline[$i] >= -128 && $myline[$i] <= 127) {
						$myfieldtype[$i] = "I1";
					} elsif ($myline[$i] >= -32768 && $myline[$i] <= 32767) {
						$myfieldtype[$i] = "I2";
					} elsif ($myline[$i] >= -2147483648 && $myline[$i] <= 2147483647) {
						$myfieldtype[$i] = "I4";
					} elsif ($myline[$i] >= -9223372036854775808 && $myline[$i] <= 9223372036854775807) {
						$myfieldtype[$i] = "I8";
					}

				} else {

					if ($myfieldmintype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldminval[$i] = $myline[$i] if ($myfieldminval[$i] gt $myline[$i]);
					} else {
						if ($myfieldminval[$i] > $myline[$i]) {
							$myfieldminval[$i] = $myline[$i];
							$myfieldmintype[$i] = "I";
						}
					}
					if ($myfieldmaxtype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldmaxval[$i] = $myline[$i] if ($myfieldmaxval[$i] lt $myline[$i]);
					} else {
						if ($myfieldmaxval[$i] < $myline[$i]) {
							$myfieldmaxval[$i] = $myline[$i];
							$myfieldmaxtype[$i] = "I";
						}
					}

					if ($myfieldtype[$i] =~ /^(DA|TS|T)$/) {
						$myfieldtype[$i] = "C";
					} elsif ($myfieldtype[$i] =~ /^I[1248]$/) {
						# Value is integer, evaluate the proper size and migrate to a larger one if required
						if ($myline[$i] >= -128 && $myline[$i] <= 127 && $myfieldtype[$i] eq "I1") {
							$myfieldtype[$i] = "I1";
						} elsif ($myline[$i] >= -32768 && $myline[$i] <= 32767 && ($myfieldtype[$i] eq "I1" || $myfieldtype[$i] eq "I2")) {
							$myfieldtype[$i] = "I2";
						} elsif ($myline[$i] >= -2147483648 && $myline[$i] <= 2147483647 && ($myfieldtype[$i] eq "I1" || $myfieldtype[$i] eq "I2" || $myfieldtype[$i] eq "I4")) {
							$myfieldtype[$i] = "I4";
						} elsif ($myline[$i] >= -9223372036854775808 && $myline[$i] <= 9223372036854775807 && ($myfieldtype[$i] eq "I1" || $myfieldtype[$i] eq "I2" || $myfieldtype[$i] eq "I4" || $myfieldtype[$i] eq "I8")) {
							$myfieldtype[$i] = "I8";
						}
					}
				}

			} elsif ($myline[$i] =~ /^[\-\+]?\d*\.\d*$/) {
				# Decimal

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = $myline[$i];
					$myfieldmaxval[$i] = $myline[$i];
					$myfieldmintype[$i] = "D";
					$myfieldmaxtype[$i] = "D";
					$myfieldtype[$i] = "D";
					$myline[$i] =~ /^[\-\+]?(\d*)\.(\d*)$/;
					$myfieldnumprecdigit[$i] = length($1);
					$myfieldnumfracdigit[$i] = length($2);

				} else {

					$myline[$i] =~ /^[\-\+]?(\d*)\.(\d*)$/;
					$y = length($1);
					$x = length($2);
					$myfieldnumprecdigit[$i] = $y if ((defined($myfieldnumprecdigit[$i]) && $myfieldnumprecdigit[$i] < $y) || (!defined($myfieldnumprecdigit[$i])));
					$myfieldnumfracdigit[$i] = $x if ((defined($myfieldnumfracdigit[$i]) && $myfieldnumfracdigit[$i] < $x) || (!defined($myfieldnumfracdigit[$i])));

					if ($myfieldmintype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldminval[$i] = $myline[$i] if ($myfieldminval[$i] gt $myline[$i]);
					} else {
						if ($myfieldminval[$i] > $myline[$i]) {
							$myfieldminval[$i] = $myline[$i];
							$myfieldmintype[$i] = "D";
						}
					}
					if ($myfieldmaxtype[$i] =~ /^(C|DA|TS|T)$/) {
						$myfieldmaxval[$i] = $myline[$i] if ($myfieldmaxval[$i] lt $myline[$i]);
					} else {
						if ($myfieldmaxval[$i] < $myline[$i]) {
							$myfieldmaxval[$i] = $myline[$i];
							$myfieldmaxtype[$i] = "D";
						}
					}

					if ($myfieldtype[$i] =~ /^(I[1248])$/) {
						$myfieldtype[$i] = "D";
					} elsif ($myfieldtype[$i] ne "D") {
						$myfieldtype[$i] = "C";
					}

				}

			} else {
				# everything else

				unless (defined($myfieldtype[$i])) {

					# initial definition for column
					$myfieldminval[$i] = $myline[$i];
					$myfieldmaxval[$i] = $myline[$i];
					$myfieldmintype[$i] = "C";
					$myfieldmaxtype[$i] = "C";
					$myfieldnumfracdigit[$i] = 0;
					$myfieldnumprecdigit[$i] = 0;

				} else {

					if ($myfieldminval[$i] gt $myline[$i]) {
						$myfieldminval[$i] = $myline[$i];
						$myfieldmintype[$i] = "C";
					}
					if ($myfieldmaxval[$i] lt $myline[$i]) {
						$myfieldmaxval[$i] = $myline[$i];
						$myfieldmaxtype[$i] = "C";
					}

				}

				$myfieldtype[$i] = "C";

			}

		} else {

			# column is null
			$myfieldnull[$i] = "yes";

		}

	}

}

close $io;

print "FieldName\tFieldNo\tDataType\tCharacterset\tCasespecific\tRequired\tFormat\tMinValue\tMaxValue\tMVC starting here\n";

for (my $i=0; $i <= $numfields; $i++) {
#	warn "$i\n";

	if (defined($myfieldtype[$i])) {

		if ($myfieldtype[$i] eq "C") {

			if ($myfieldlen[$i] <= $maxchar) {
				$datatype = "CHAR(";
			} else {
				$datatype = "VARCHAR(";
			}
			if ($myfieldlen[$i] < $minvarchar && $datatype eq "VARCHAR(") {
				$len = $minvarchar;
			} else {
				$len = $myfieldlen[$i];
			}
			$datatype .= "$len)";

		} elsif ($myfieldtype[$i] eq "DA") {

			$datatype = "DATE";

		} elsif ($myfieldtype[$i] eq "I1") {

			$datatype = "BYTEINT";

		} elsif ($myfieldtype[$i] eq "I2") {

			$datatype = "SMALLINT";

		} elsif ($myfieldtype[$i] eq "I4") {

			$datatype = "INTEGER";

		} elsif ($myfieldtype[$i] eq "I8") {

			$datatype = "BIGINT";

		} elsif ($myfieldtype[$i] eq "D") {

			$prec = 0;
			if ($myfieldnumprecdigit[$i] + $myfieldnumfracdigit[$i] < 3) {
				$prec = 2;
			} elsif ($myfieldnumprecdigit[$i] + $myfieldnumfracdigit[$i] < 5) {
				$prec = 4;
			} elsif ($myfieldnumprecdigit[$i] + $myfieldnumfracdigit[$i] < 10) {
				$prec = 9;
			} elsif ($myfieldnumprecdigit[$i] + $myfieldnumfracdigit[$i] < 19) {
				$prec = 18;
			} elsif ($myfieldnumprecdigit[$i] + $myfieldnumfracdigit[$i] < 39) {
				$prec = 38;
			}
			$datatype = "DECIMAL(" . $prec . "," . $myfieldnumfracdigit[$i] . ")";

		} elsif ($myfieldtype[$i] eq "TS") {

			$datatype = "TIMESTAMP(" . $myfieldnumfracdigit[$i] . ")";

		} elsif ($myfieldtype[$i] eq "T") {

			$datatype = "TIME(" . $myfieldnumfracdigit[$i] . ")";

		}

		if (!defined($myfieldnull[$i]) || $myfieldnull[$i] ne "yes") {
			$required = "yes";
		} else {
			$required = "no";
		}

		printf("%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s", $myheader[$i], ($i+1), $datatype, "", "", $required, "", $myfieldminval[$i], $myfieldmaxval[$i]);

		foreach $val (keys(%{$myfieldval[$i]})) {
			unless ($myfieldtype[$i] =~ /^(D|I[1248])$/ && $val eq ".") {
				print "\t$val";
			}
		}

		print "\n";

	} else {

		printf("%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $myheader[$i], ($i+1), "BYTEINT", "", "", "no", "", "", "");

	}
}
