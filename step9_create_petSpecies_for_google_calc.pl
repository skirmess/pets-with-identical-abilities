#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;

my %pets;

my %realCashPets = (
	92 => 1,
	93 => 1,
	94 => 1,
	107 => 1,
	111 => 1,
	121 => 1,
	124 => 1,
	131 => 1,
	155 => 1,
	170 => 1,
	171 => 1,
	179 => 1,
	180 => 1,
	188 => 1,
	189 => 1,
	217 => 1,
	228 => 1,
	231 => 1,
	240 => 1,
	245 => 1,
	246 => 1,
	247 => 1,
	248 => 1,
	249 => 1,
	256 => 1,
	258 => 1,
	268 => 1,
	294 => 1,
	297 => 1,
	316 => 1,
	329 => 1,
	346 => 1,
	347 => 1,
	671 => 1,
	757 => 1,
	758 => 1,
	903 => 1,
	1073 => 1,
	1117 => 1,
	1127 => 1,
	1168 => 1,
	1248 => 1,
	1363 => 1,
	1364 => 1,
	1365 => 1,
	1386 => 1,
	1602 => 1,
	1603 => 1,
);

open(B, "BreedsPerPet.csv") or die "$!";
while (my $line = <B>) {
	chomp $line;
	my @pet = split(/\s*;/, $line);

	next if ( $pet[0] !~ m/^[0-9]+$/ );

	if ( ! defined $pets{$pet[0]} ) {
		$pets{$pet[0]} = $pet[3];
	}
	elsif ( $pets{$pet[0]} ne $pet[3] ) {
		die "error in csv."
	}
}
close(B) or die "$!";

open(P, ">petSpecies.txt") or die "$!";

foreach my $id ( sort { $a <=> $b } keys %pets) {
	print P "  ";
	if ( defined $realCashPets{$id} ) {
		print P "//";
	}
	print P "petSpecies[$id] = \"$pets{$id}\";\n";
}

close(P) or die "$!";
