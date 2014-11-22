#!/usr/bin/perl -w

$zeile = 0;

$len_min = 7;
$len_max = 7;
$len_distinct = 2;
$len_maxlen = 6;
$len_nulls = 5;
$len_distinct = 2;

while (<>) {

	chomp;

	$zeile++;

	@zeile = split(/\|/);

	$i = 0;

	# Zaehle die Anzahl der Felder
	$felder{($#zeile+1)}++;

	foreach $x (@zeile) {
		$x =~ s/^\s+//;
		$x =~ s/\s+$//;
		$anzahl_nulls[$i] = 0 unless (defined($anzahl_nulls[$i]));
		$max_attribut_laenge[$i] = length($x) unless (defined($max_attribut_laenge[$i]));
		$max_attribut_laenge[$i] = length($x) if ($max_attribut_laenge[$i] < length($x));
		$anzahl_nulls[$i] += 1 if ($x eq "");
		$len_nulls = length($anzahl_nulls[$i]) if ($len_nulls < length($anzahl_nulls[$i]));
		$distinct_values[$i]{$x}++ if ($x ne "");
		$len_distinct = length(scalar(keys %{ $distinct_values[$i] })) if ($len_distinct < length(scalar(keys %{ $distinct_values[$i] })));

		unless (defined($attribut_type[$i])) {
			$y = $x;
			$y =~ tr/1234567890\.\,\-\+\ //d;
			if (length($y) > 0) {
				$attribut_type[$i] = "char";
			} elsif (defined($x)) {
				$attribut_type[$i] = "num";
			}
			$fuehrende_nullen[$i] = "";
			$anzahl_nulls[$i] = 0;
		}

		if (defined($attribut_type[$i]) && $attribut_type[$i] eq "num" && defined($x) && $x gt "") {
			$x =~ s/(.*)(\-)$/$2$1/;
			$y = $x;
			$y =~ tr/1234567890\.\,\-\+\ //d;
			$x =~ s/ //g;
			$attribut_type[$i] = "char" if length($y) > 0;
			$attribut_type[$i] = "char" if (index($x, "-") > 1 && index($x, "-") < length($x));
			$attribut_type[$i] = "char" if (index($x, "+") > 1 && index($x, "+") < length($x));
			$attribut_type[$i] = "char" if (index($x, " ") > 1 && index($x, " ") < length($x));
		} elsif (defined($attribut_type[$i]) && $attribut_type[$i] eq "char" && defined($x) && $x gt "") {
			$fuehrende_nullen[$i] = "";
		}

		if (defined($attribut_type[$i]) && defined($x) && $x gt "") {
			if ($attribut_type[$i] eq "num") {
				$max_wert[$i] = $x unless (defined($max_wert[$i]));
				$min_wert[$i] = $x unless (defined($min_wert[$i]));
				$max_wert[$i] = $x if ($max_wert[$i] < $x);
				$min_wert[$i] = $x if ($min_wert[$i] > $x);
				$fuehrende_nullen[$i] = "J" if ($x > 0 && $x =~ /^0+/);
				$len_min = length($min_wert[$i]) if ($len_min < length($min_wert[$i]));
				$len_max = length($max_wert[$i]) if ($len_max < length($max_wert[$i]));
				$len_maxlen = length($len_max) if ($len_maxlen < length($len_maxlen));
			} elsif ($attribut_type[$i] eq "char") {
				$max_wert[$i] = $x unless (defined($max_wert[$i]));
				$min_wert[$i] = $x unless (defined($min_wert[$i]));
				$max_wert[$i] = $x if ($max_wert[$i] lt $x);
				$min_wert[$i] = $x if ($min_wert[$i] gt $x);
				$len_min = length($min_wert[$i]) if ($len_min < length($min_wert[$i]));
				$len_max = length($max_wert[$i]) if ($len_max < length($max_wert[$i]));
				$len_maxlen = length($len_max) if ($len_maxlen < length($len_maxlen));
			}
		}

		$i++;
	}

}

$len_att = length(($#max_attribut_laenge + 1));

print("+-", "-" x $len_att, "-+------+-", "-" x $len_maxlen, "-+-", "-" x ${len_min}, "-+-", "-" x ${len_max}, "-+-", "-" x ${len_nulls}, "-+----+-", "-" x ${len_distinct}, "-+\n");
printf("| %${len_att}s | Type | %${len_maxlen}s | %${len_min}s | %${len_max}s | %${len_nulls}s | f0 | %${len_distinct}s |\n", "#", "MaxLen", "MinWert", "MaxWert", "Nulls", "DV");
print("+-", "-" x $len_att, "-+------+-", "-" x $len_maxlen, "-+-", "-" x ${len_min}, "-+-", "-" x ${len_max}, "-+-", "-" x ${len_nulls}, "-+----+-", "-" x ${len_distinct}, "-+\n");

$i = 0;
foreach $x (@max_attribut_laenge) {

	printf("| %${len_att}i | %-4s | %${len_maxlen}i | %${len_min}s | %${len_max}s | %${len_nulls}i | %2s | %${len_distinct}i |\n", ($i + 1), $attribut_type[$i], $x, $min_wert[$i], $max_wert[$i], $anzahl_nulls[$i], $fuehrende_nullen[$i], scalar(keys %{ $distinct_values[$i] })) if ($attribut_type[$i] =~ /num/);
	printf("| %${len_att}i | %-4s | %${len_maxlen}i | %-${len_min}s | %-${len_max}s | %${len_nulls}i |    | %${len_distinct}i |\n", ($i + 1), $attribut_type[$i], $x, $min_wert[$i], $max_wert[$i], $anzahl_nulls[$i], scalar(keys %{ $distinct_values[$i] })) if ($attribut_type[$i] =~ /char/);

	$i++;
}

print("+-", "-" x $len_att, "-+------+-", "-" x $len_maxlen, "-+-", "-" x ${len_min}, "-+-", "-" x ${len_max}, "-+-", "-" x ${len_nulls}, "-+----+-", "-" x ${len_distinct}, "-+\n");
$a = sprintf("| Anzahl Sätze gesamt: %i", $zeile);
print $a, " " x (($len_att + $len_maxlen + ${len_min} + ${len_max} + $len_nulls + ${len_distinct} + 30) - length($a)), "|\n";

if (scalar(keys(%felder)) > 1) {
	foreach $x (sort {$a <=> $b} (keys(%felder))) {
		$a = sprintf("| Anzahl Sätze mit %i Attributen: %i", $x, $felder{$x});
		print $a, " " x (($len_att + $len_maxlen + ${len_min} + ${len_max} + $len_nulls + ${len_distinct} + 30) - length($a)), "|\n";
	}
}

print("+-", "-" x ($len_att + $len_maxlen + ${len_min} + ${len_max} + $len_nulls + ${len_distinct}), "----------------------------+\n");

exit(0);
