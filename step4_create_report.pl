#!/usr/bin/perl -w

use strict;

use Digest::MD5 qw(md5 md5_hex md5_base64);

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
		foreach my $s (split(/[}][,][{]/, $spells)) {
			$s =~ s/^{//;
			$s =~ s/}$//;
			push(@spells, "$s");
		}

		foreach my $s (sort(@spells)) {
			if ( $s =~ m/"name":"([^"]+)"/ ) {
				$spellSetName .= '|[ability]'.$1.'[/ability]';
			}
			$ctx->add("$s\n");
		}
	}
	my $digest = $ctx->hexdigest;

	$spells[$dent] = $digest;

	$spellSetName =~ s/^\|//;
	$spellSetName{$digest} = $spellSetName;
}
closedir(D) or die "$!";

my %classic_sort = (
	Aquatic => [
		qr{Water Jet.*Tongue Lash.*Healing Wave.*Cleansing Rain.*Frog Kiss.*Swarm of Flies}sm,
		qr{Rip.*Claw.*Spiny Carapace.*Shell Shield.*Dive.*Blood in the Water}sm,
		qr{Bite.*Grasp.*Shell Shield.*Healing Wave.*Headbutt.*Powerball}sm,
		qr{Bite.*Gnaw.*Screech.*Survival.*Surge.*Dive}sm,
		qr{Peck.*Surge.*Frost Spit.*Slippery Ice.*Ice Lance.*Belly Slide}sm,
		qr{Snap.*Surge.*Renewing Mists.*Healing Wave.*Shell Shield.*Whirlpool}sm,
		qr{Water Jet.*Poison Spit.*Healing Wave.*Cleansing Rain.*Soothe.*Pump}sm,
	],
	Beast => [
		qr{Claw.*Pounce.*Rake.*Screech.*Devour.*Prowl}sm,
		qr{Bite.*Roar.*Hibernate.*Bash.*Maul.*Rampage}sm,
		qr{Snap.*Triple Snap.*Crouch.*Screech.*Sting.*Rampage}sm,
		qr{Bite.*Flank.*Leap.*Screech.*Devour.*Exposed Wounds}sm,
		qr{Smash.*Rake.*Roar.*Clobber.*Banana Barrage.*Barrel Toss}sm,
		qr{Strike.*Poison Spit.*Sticky Web.*Brittle Webbing.*Leech Life.*Spiderling Swarm}sm,
		qr{Chomp.*Consume.*Acidic Goo.*Sticky Goo.*Leap.*Burrow}sm,
		qr{Bite.*Water Jet.*Takedown.*Stoneskin.*Clobber.*Headbutt}sm,
		qr{Gnaw.*Bite.*Ravage.*Body Slam.*Puncture Wound.*Takedown}sm,
		qr{Trihorn Charge.*Trample.*Horn Attack.*Stampede.*Primal Cry.*Trihorn Shield}sm,
		qr{Smash.*Trample.*Survival.*Trumpet Strike.*Horn Attack.*Stampede}sm,
		qr{Bite.*Flurry.*Crouch.*Howl.*Leap.*Dazzling Dance}sm,
		qr{Bite.*Poison Fang.*Hiss.*Counterstrike.*Burrow.*Vicious Fang}sm,
		qr{Hoof.*Chew.*Comeback.*Soothe.*Headbutt.*Stampede}sm,
		qr{Claw.*Quick Attack.*Screech.*Triple Snap.*Comeback.*Ravage}sm,
	],
	Critter	=> [
		qr{Bite.*Comeback.*Perk Up.*Buried Treasure.*Burrow.*Trample}sm,
		qr{Scratch.*Flurry.*Adrenaline Rush.*Dodge.*Burrow.*Stampede}sm,
		qr{Ooze Touch.*Absorb.*Acidic Goo.*Shell Shield.*Dive.*Headbutt}sm,
		qr{Scratch.*Flank.*Hiss.*Survival.*Swarm.*Apocalypse}sm,
		qr{Hoof.*Stampede.*Tranquility.*Nature's Ward.*Bleat.*Headbutt}sm,
		qr{Scratch.*Woodchipper.*Adrenaline Rush.*Crouch.*Nut Barrage.*Stampede}sm,
		qr{Scratch.*Comeback.*Flurry.*Poison Fang.*Stampede.*Survival}sm,
		qr{Scratch.*Flurry.*Sting.*Survival.*Stampede.*Comeback}sm,
		qr{Burn.*Flank.*Hiss.*Cauterize.*Scorched Earth.*Apocalypse}sm,
		qr{Scratch.*Thrash.*Shell Shield.*Roar.*Infected Claw.*Powerball}sm,
		qr{Chomp.*Adrenaline Rush.*Leap.*Crouch.*Burrow.*Comeback}sm,
		qr{Chomp.*Comeback.*Crouch.*Adrenaline Rush.*Leap.*Burrow}sm,
		qr{Bite.*Poison Fang.*Spiked Skin.*Counterstrike.*Survival.*Powerball}sm,
		qr{Scratch.*Flurry.*Rake.*Perk Up.*Stench.*Bleat}sm,
		qr{Bite.*Tongue Lash.*Survival.*Counterstrike.*Poison Fang.*Powerball}sm,
		qr{Hoof.*Chew.*Comeback.*Soothe.*Bleat.*Stampede}sm,
		qr{Skitter.*Screech.*Swarm.*Cocoon Strike.*Nature's Touch.*Inspiring Song}sm,
	],
	Dragonkin => [
		qr{Breath.*Tail Sweep.*Healing Flame.*Scorched Earth.*Lift-Off.*Deep Breath}sm,
		qr{Shadowflame.*Tail Sweep.*Roar.*Call Darkness.*Lift-Off.*Deep Breath}sm,
		qr{Claw.*Quills.*Rake.*Conflagrate.*Flame Breath.*Flamethrower}sm,
		qr{Slicing Wind.*Arcane Blast.*Evanescence.*Life Exchange.*Moonfire.*Cyclone}sm,
	],
	Elemental => [
		qr{Burn.*Flame Breath.*Immolate.*Scorched Earth.*Conflagrate.*Immolation}sm,
		qr{Burn.*Leech Life.*Sticky Web.*Poison Spit.*Stone Rush.*Stoneskin}sm,
		qr{Feedback.*Spark.*Crystal Overload.*Amplify Magic.*Stone Rush.*Elementium Bolt}sm,
		qr{Scratch.*Ironbark.*Thorns.*Poisoned Branch.*Photosynthesis.*Entangling Roots}sm,
	],
	Flying => [
		qr{Scratch.*Slicing Wind.*Glowing Toxin.*Sting.*Confusing Sting.*Dazzling Dance}sm,
		qr{Peck.*Slicing Wind.*Squawk.*Adrenaline Rush.*Egg Barrage.*Flock}sm,
		qr{Slicing Wind.*Thrash.*Cyclone.*Adrenaline Rush.*Hawk Eye.*Lift-Off}sm,
		qr{Slicing Wind.*Thrash.*Hawk Eye.*Adrenaline Rush.*Lift-Off.*Cyclone}sm,
		qr{Deep Burn.*Fire Quills.*Shriek.*Scorched Earth.*Cauterize.*Predatory Strike}sm,
		qr{Bite.*Leech Life.*Screech.*Hawk Eye.*Reckless Strike.*Nocturnal Strike}sm,
		qr{Peck.*Slicing Wind.*Squawk.*Gobble Strike.*Food Coma.*Flock}sm,
		qr{Slicing Wind.*Peck.*Rain Dance.*Flyby.*Lift-Off.*Nocturnal Strike}sm,
		qr{Peck.*Quills.*Shriek.*Cyclone.*Nocturnal Strike.*Predatory Strike}sm,
		qr{Barbed Stinger.*Bite.*Focus.*Predatory Strike.*Puncture Wound.*Ravage}sm,
		qr{Slicing Wind.*Reckless Strike.*Cocoon Strike.*Counterspell.*Moth Dust.*Call Lightning}sm,
		qr{Slicing Wind.*Alpha Strike.*Cocoon Strike.*Adrenaline Rush.*Moth Balls.*Moth Dust}sm,
		qr{Scratch.*Slicing Wind.*Confusing Sting.*Cocoon Strike.*Swarm.*Glowing Toxin}sm,
		qr{Bite.*Arcane Blast.*Tail Sweep.*Slicing Wind.*Shadow Shock.*Lash}sm,
	],
	Humanoid => [
		qr{Crush.*Tongue Lash.*Sticky Goo.*Poison Lash.*Backflip.*Dreadful Breath}sm,
	],
	Magic => [
		qr{Ooze Touch.*Absorb.*Corrosion.*Creeping Ooze.*Expunge.*Acidic Goo}sm,
		qr{Feedback.*Flurry.*Drain Power.*Amplify Magic.*Mana Surge.*Deflection}sm,
	],
	Mechanical => [
		qr{Peck.*Batter.*Overtune.*Rebuild.*Supercharge.*Wind-Up}sm,
		qr{Metal Fist.*Thrash.*Overtune.*Extra Plating.*Demolish.*Repair}sm,
		qr{Missile.*Batter.*Toxic Smoke.*Minefield.*Sticky Grenade.*Launch Rocket}sm,
	],
);

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

	$pets{$type}{$spells[$species]}{"name"}{$species} += 1;
	$pets{$type}{$spells[$species]}{"stat"}{$health.'/'.$power.'/'.$speed}{$name} = $breed;
}
close(F) or die "$!";

foreach my $type (sort keys %pets) {
	open(FT, ">report/$type.txt") or die "$!";
	my %ft_content;
	foreach my $spellSet (keys %{ $pets{$type} } ) {

		my $ft_content = '';
		my $count = keys %{ $pets{$type}{$spellSet}{"name"} };
		if ( $count > 1 ) {

			my $multipleBreeds = 0;
			foreach my $species (keys %{ $pets{$type}{$spellSet}{"name"} }) {
				if ( $pets{$type}{$spellSet}{"name"}{$species} > 1 ) {
					$multipleBreeds = 1;
				}
			}
			if ( $multipleBreeds == 0 ) {
				next;
			}

			$ft_content .= "[B]$type $spellSetName{$spellSet}".'[/B]'."\n";
			$ft_content .= '[list]'."\n";
			foreach my $kS ( reverse sort keys %{ $pets{$type}{$spellSet}{"stat"} } ) {
				$ft_content .= '[*]'."$kS\n";
				$ft_content .= '[list]'."\n";
				my $lastBreed = undef;
				my $lastName;
				foreach my $kN ( sort keys %{ $pets{$type}{$spellSet}{"stat"}{$kS} } ) {
					$ft_content .= '[*][pet]'.$kN.'[/pet]';
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
					$ft_content .= " $breedName ($breed)\n";

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
				$ft_content .= '[/list]'."\n";
			}
			$ft_content .= '[/list]'."\n";

			my $x = (split /\n/, $ft_content)[0];
			$ft_content{$x} = $ft_content;
		}
	}

	for my $k (sort {
		for my $r ( @{ $classic_sort{$type} } ) {
			return -1 if $a =~ m{$r};
			return  1 if $b =~ m{$r};
		}

		die q{DEBUG: don't know how to sort};
		# return $a cmp $b;
		} keys %ft_content) {
		print FT $ft_content{$k};
	}
	close(FT) or die "$!";
}
