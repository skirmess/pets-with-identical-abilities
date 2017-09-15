#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(abs_path);
use FindBin;
#use lib abs_path("$FindBin::Bin/perl/share/perl5");

use JSON qw( decode_json );

use Digest::MD5 qw(md5 md5_hex md5_base64);

my @spells;
my %spell_set_name;
my @species;

opendir(my $species_fh, "species") or die "$!";
while (my $dent = readdir($species_fh)) {
	next if ( ( $dent eq '.' ) or ( $dent eq '..') );
	next if ( $dent eq '.git' );

	open(my $fh, "<", "species/$dent") or die "$!";
	my $species_json;
	{
		local $/;
		$species_json = <$fh>;
	}
	close($fh) or die "$!";

	my $species     = decode_json($species_json);
	my $name        = $species->{name};
	my $species_id  = $species->{speciesId};
	$species[$dent] = $species;

	die "File species/$dent is for species $species_id" if ( $dent ne $species_id );

	my @spells_used;
	ABILITY:
	for my $ability (@{ $species->{abilities} }) {
		next ABILITY if ( $ability->{slot} == -1 );

		$spells_used[$ability->{order}] = $ability->{name};
	}

	die "expected 6 spells but got ".scalar @spells_used if ( @spells_used != 6 );

	my $spell_set_name;
	for my $i (0, 3, 1, 4, 2, 5) {
		die "spell $i not defined" if ( !$spells_used[$i] );

		$spell_set_name .= '|[ability]'.$spells_used[$i].'[/ability]';
	}

	$spell_set_name =~ s{ ^ [|] }{}xsm;

	my $ctx = Digest::MD5->new;
	$ctx->add($spell_set_name);

	my $digest = $ctx->hexdigest;

	$spells[$dent] = $digest;
	$spell_set_name{$digest} = $spell_set_name;
}
closedir($species_fh) or die "$!";

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
	Critter => [
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

my %pet_types = (
	0 => 'Humanoid',
	1 => 'Dragonkin',
	2 => 'Flying',
	3 => 'Undead',
	4 => 'Critter',
	5 => 'Magic',
	6 => 'Elemental',
	7 => 'Beast',
	8 => 'Aquatic',
	9 => 'Mechanical',
);

my %seen_pet_by_id;
my %seen_pet_by_name;
open(my $fh, "<", "BreedsPerPet.csv") or die "$!";
while (my $line = <$fh>) {
	chomp $line;
	next if ($line !~ m/^\d/);
	my ($species, $breed, undef, undef, undef, undef, undef, undef, $health, $power, $speed) = split(/\s*;/, $line);

	die "No species file for species $species" if ( !defined $species[$species] );

	my $type = $species[$species]->{petTypeId};

	$type = $pet_types{$type};
	if ( !defined $type) {
		die "Unknown pet type id '$species[$species]->{petTypeId}'";
	}

	my $name = $species[$species]->{name};

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

	if ( $name eq '' ) {
		die "no name defined for species $species";
	}

	if ( defined $seen_pet_by_id{$species} ) {
		if ( $name ne $seen_pet_by_id{$species} ) {
			die "different name ($name, $seen_pet_by_id{$species} for same species ($species)";
		}
	}
	else {
		$seen_pet_by_id{$species} = $name;
	}

	if ( defined $seen_pet_by_name{$name} ) {
		if ( $species ne $seen_pet_by_name{$name} ) {
			die "different species ($species, $seen_pet_by_name{$name}) for same name ($name)";
		}
	}
	else {
		$seen_pet_by_name{$name} = $species;
	}

	$pets{$type}{$spells[$species]}{"name"}{$species} += 1;
	$pets{$type}{$spells[$species]}{"stat"}{$health.'/'.$power.'/'.$speed}{$name} = $breed;
}
close($fh) or die "$!";

foreach my $type (sort keys %pets) {
	open($fh, ">", "report/$type.txt") or die "$!";
	my %ft_content;
	foreach my $spell_set (sort keys %{ $pets{$type} } ) {

		my $ft_content = '';
		my $count = keys %{ $pets{$type}{$spell_set}{"name"} };
		if ( $count > 1 ) {

			my $multipleBreeds = 0;
			foreach my $species (keys %{ $pets{$type}{$spell_set}{"name"} }) {
				if ( $pets{$type}{$spell_set}{"name"}{$species} > 1 ) {
					$multipleBreeds = 1;
				}
			}
			if ( $multipleBreeds == 0 ) {
				next;
			}

			$ft_content .= "[B]$type $spell_set_name{$spell_set}".'[/B]'."\n";
			$ft_content .= '[list]'."\n";
			foreach my $kS ( reverse sort keys %{ $pets{$type}{$spell_set}{"stat"} } ) {
				$ft_content .= '[*]'."$kS\n";
				$ft_content .= '[list]'."\n";
				my $lastBreed = undef;
				my $lastName;
				foreach my $kN ( sort keys %{ $pets{$type}{$spell_set}{"stat"}{$kS} } ) {
					$ft_content .= '[*][pet]'.$kN.'[/pet]';
					my $breed = $pets{$type}{$spell_set}{stat}{$kS}{$kN};
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
		return $a cmp $b;
		} keys %ft_content) {
		print $fh $ft_content{$k};
	}
	close($fh) or die "$!";

}
