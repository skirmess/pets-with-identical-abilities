#!/usr/bin/perl -w

use strict;

opendir(D, "species") or die "$!";

while (my $dent = readdir(D)) {
	next if ( ( $dent eq '.' ) or ( $dent eq '..' ));

	open(F, "species/$dent") or die "$!";
	my $x = "";
	while (my $line = <F>) {
		chomp $line;
		$x .= $line;
	}

	close(F) or die "$!";

	my $species = -1;
	my $name = "-1";
	if ($x =~ m/"speciesId":(\d+),/) {
		$species = $1;
	}
	if ($x =~ m/"name":"([^"]+)",/) {
		$name = $1;
	}

	print "$species $name\n";
}

closedir(D);

