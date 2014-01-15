#!/usr/bin/perl -w

use strict;

use Digest::MD5 qw(md5 md5_hex md5_base64);

#`rm -rf digest`;
#mkdir("digest") or die "$!";

##opendir(D, "digest") or die "$!";
##while (my $dent = readdir(D)) {
##	next if ( ( $dent eq '.' ) or ( $dent eq '..') );
##	unlink("digest/$dent");
##}
##closedir(D) or die "$!";

my @spells;
my %spellSetName;

opendir(D, "species") or die "$!";
while (my $dent = readdir(D)) {
	next if ( ( $dent eq '.' ) or ( $dent eq '..') );
	next if ( $dent eq '.svn' );

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

	my $spellSetName = "";
	my $ctx = Digest::MD5->new;

	if ( $x =~ m/\[(.*)\]/ ) {
		my $spells = $1;
		my @spells;
		foreach my $s (split(/},{/, $spells)) {
			$s =~ s/^{//;
			$s =~ s/}$//;
			# print "$s\n";
			push(@spells, "$s");
		}

		foreach my $s (sort(@spells)) {
			if ( $s =~ m/"name":"([^"]+)"/ ) {
				$spellSetName .= '|[ability]'.$1.'[/ability]';
			}
#			else {
#				die;
#			}
			$ctx->add("$s\n");
		}
	}
	my $digest = $ctx->hexdigest;

#	#open(F, ">>digest/$digest") or die "$!";
#	#print F "$species $name\n";
#	#close(F) or die "$!";

	$spells[$dent] = $digest;

	$spellSetName =~ s/^\|//;
	$spellSetName{$digest} = $spellSetName;
}
closedir(D) or die "$!";

my %pets;

my %seenPetById;
my %seenPetByName;
open(F, "BreedsPerPet.csv") or die "$!";
while (my $line = <F>) {
	chomp $line;
	next if ($line !~ m/^\d/);
	my ($species, $breed, $type, $name, undef, undef, undef, undef, $health, $power, $speed) = split(/\s*;/, $line);
	if ( $breed > 12 ) {
		$breed = $breed - 10;
	}
	if ( $name eq "Moonkin Hatchling" ) {
		if ( $species eq "296" ) {
			$name = "$name (Alliance)";
		}
		elsif ( $species eq "298" ) {
			$name = "$name (Horde)";
		}
	}

	if ( defined $seenPetById{$species} ) {
		if ( $name ne $seenPetById{$species} ) {
			die "different name ($name, $seenPetById{$species} for same species ($species)";
		}
	}
	else {
		$seenPetById{$species} = $name;
	}

	if ( defined $seenPetByName{$name} ) {
		if ( $species ne $seenPetByName{$name} ) {
			die "different species ($species, $seenPetByName{$name}) for same name ($name)";
		}
	}
	else {
		$seenPetByName{$name} = $species;
	}

#	# print "$species; $breed; $name; $type; $health; $power; $speed; $spells[$species]\n";
#	my $digest = $spells[$species];
#	if ( ! -d "digest/$digest.$type" ) {
#		mkdir("digest/$digest.$type") or die "$!";
#	}

#	open(F2, ">>digest/$digest.$type/$health-$power-$speed") or die "$!";
#	print F2 "$species; $name; $breed\n";
#	close(F2) or die "$!";

	$pets{$type}{$spells[$species]}{"name"}{$species} = 1;
	$pets{$type}{$spells[$species]}{"stat"}{$health.'/'.$power.'/'.$speed}{$name} = $breed;
}
close(F) or die "$!";

foreach my $type (sort keys %pets) {
	open(FT, ">report/$type.txt") or die "$!";
	foreach my $spellSet (keys %{ $pets{$type} } ) {

		my $count = keys %{ $pets{$type}{$spellSet}{"name"} };
		if ( $count > 1 ) {
			# print "$k $x\n";
			print FT "[B]$type $spellSetName{$spellSet}".'[/B]'."\n";
			print FT '[list]'."\n";
			foreach my $kS ( reverse sort keys %{ $pets{$type}{$spellSet}{"stat"} } ) {
				print FT '[*]'."$kS\n";
				print FT '[list]'."\n";
				my $lastBreed = undef;
				my $lastName;
				foreach my $kN ( keys %{ $pets{$type}{$spellSet}{"stat"}{$kS} } ) {
					print FT '[*][pet]'.$kN.'[/pet]';
					my $breed = $pets{$type}{$spellSet}{stat}{$kS}{$kN};
					my $breedName = "";
					if ( $breed == 3 ) {
						$breedName = "B/B";
					}
					elsif ( $breed == 4 ) {
						$breedName = "P/P";
					}
					elsif ( $breed == 5 ) {
						$breedName = "S/S";
					}
					elsif ( $breed == 6 ) {
						$breedName = "H/H";
					}
					elsif ( $breed == 7 ) {
						$breedName = "H/P";
					}
					elsif ( $breed == 8 ) {
						$breedName = "P/S";
					}
					elsif ( $breed == 9 ) {
						$breedName = "H/S";
					}
					elsif ( $breed == 10 ) {
						$breedName = "P/B";
					}
					elsif ( $breed == 11 ) {
						$breedName = "S/B";
					}
					elsif ( $breed == 12 ) {
						$breedName = "H/B";
					}
					else {
						die "unknown breed";
					}
					print FT " $breedName ($breed)\n";

					if ( ! defined $lastBreed ) {
						$lastBreed = $breed;
						$lastName = $kN;
					}
					else {
						if ( $lastBreed ne $breed) {
							# print "WARNING: Same stats for $breed ($kN) and $lastBreed ($lastName).\n";
						}
					}
				}
				print FT '[/list]'."\n";
			}
			print FT '[/list]'."\n";
		}

#{$health.'-'.$power.'-'.$speed}{$name} = $breed;
	}
	close(FT) or die "$!";

}
##my $in = -1;
##foreach my $c (split("",$x)) {
##	if ( $c eq '{' ) {
##		print "\n";
##		$in = $in + 1;
##		print " " x ($in * 2);
##		print "$in: $c";
##	}
##	elsif ( $c eq '}' ) {
##		print "$c";
##		$in = $in - 1;
##	}
##	else {
##		print "$c";
##	}
##}
##print "\n";

##my @ability;
##
##my $work;
##my $in = -1;
##foreach my $c (split("",$x)) {
##	if ( $c eq '{' ) {
###		print "\n";
##		$in = $in + 1;
###		print " " x ($in * 2);
###		print "$in: $c";
##		$work = $c;
##	}
##	elsif ( $c eq '}' ) {
###		print "$c";
###		$in = $in - 1;
##		$work .= $c;
##
##		print "$in: $work\n";
##
###		if ( $in == 0 ) {
###			if ($work =~ m/"speciesId":(\d+),/) {
###				$species = $1;
###			}
###			if ($work =~ m/"name":"([^"]+)",/) {
###				$name = $1;
###			}
###		}
###		else {
###			$ability[$in] = $work;
###		}
##	}
##	else {
##		# print "$c";
##		$work .= $c;
##	}
##}
###print "\n";
##
