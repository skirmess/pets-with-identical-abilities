#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use JSON qw( decode_json );
use Path::Tiny;

my %pets;
my @species;
my @spells;

main();

sub main {

    load_species_data();
    load_breeds_pet_pet();
    write_reports();
    exit 0;
}

sub load_species_data {
    for my $species_file ( path('species')->children() ) {
        my $species    = decode_json( $species_file->slurp() );
        my $name       = $species->{name};
        my $species_id = $species->{speciesId};

        # information for every species is saved in its own file and the file
        # name is the species id.
        die "File $species_file is for species $species_id" if $species_file->basename() ne $species_id;

        # save the species data in a global variable
        $species[$species_id] = $species;

        # find the 6 spells available to this species
        my @spells_used;
      ABILITY:
        for my $ability ( @{ $species->{abilities} } ) {
            next ABILITY if $ability->{slot} == -1;

            $spells_used[ $ability->{order} ] = $ability->{name};
        }
        die "expected 6 spells but got " . scalar @spells_used if @spells_used != 6;

        # generate the name of this set with these 6 specific spells
        my $spell_set_name;
        for my $i ( 0, 3, 1, 4, 2, 5 ) {
            die "spell $i not defined" if !$spells_used[$i];

            $spell_set_name .= '|[ability]' . $spells_used[$i] . '[/ability]';
        }
        $spell_set_name =~ s{ ^ [|] }{}xsm;

        # generate a global hash mapping from species id to spell set
        $spells[$species_id] = $spell_set_name;
    }

    return;
}

sub load_breeds_pet_pet {

    my %seen_pet_by_id;
    my %seen_pet_by_name;

    # map pet type numbers to names
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

    # open the csv from petsear.ch that contains all the breeds of every
    # species that are available in the game
    open my $fh, '<', 'BreedsPerPet.csv' or die "Cannot read file: $!";
    while ( my $line = <$fh> ) {
        chomp $line;

        # skip invalid lines. headers and empty lines
        next if $line !~ m/^[0-9]/;

        my ( $species, $breed, undef, undef, undef, undef, undef, undef, $health, $power, $speed ) = split /\s*;/, $line;

        # We have to update the species data if the file contains
        # information about a species that we haven't seen yet.
        die "No species file for species $species" if !defined $species[$species];

        # get the pet type name
        my $type = $pet_types{ $species[$species]->{petTypeId} };
        die "Unknown pet type id '$species[$species]->{petTypeId}'" if !defined $type;

        # and the name of the pet
        my $name = $species[$species]->{name};

        # breeds above 12 are female breeds. They are the same as male breeds
        if ( $breed > 12 ) {
            $breed -= 10;
        }

        # There are two pets with the same name. The alliance and the horde
        # Moonkin Hatchling. Give them a unique name.
        if ( $name eq "Moonkin Hatchling" ) {
            if ( $species eq "296" ) {
                $name = "$name (Alliance)";
            }
            elsif ( $species eq "298" ) {
                $name = "$name (Horde)";
            }
        }

        # Every species must have a name
        die "no name defined for species $species" if $name eq q{};

        # The file contains one line per breed. The same species is mentioned
        # on multiple lines. Check that every line with the same species id
        # has the same name.
        if ( defined $seen_pet_by_id{$species} ) {
            die "different name ($name, $seen_pet_by_id{$species} for same species ($species)" if $name ne $seen_pet_by_id{$species};
        }
        else {
            $seen_pet_by_id{$species} = $name;
        }

        # The file contains one line per breed. The same species is mentioned
        # on multiple lines. Check that every line with the same name has hte
        # same species id.
        if ( defined $seen_pet_by_name{$name} ) {
            die "different species ($species, $seen_pet_by_name{$name}) for same name ($name)" if $species ne $seen_pet_by_name{$name};
        }
        else {
            $seen_pet_by_name{$name} = $species;
        }

        # Calculates how many breeds every species has
        $pets{$type}{ $spells[$species] }{"name"}{$species} += 1;

        # stores the stats of every seen breed
        $pets{$type}{ $spells[$species] }{"stat"}{ $health . '/' . $power . '/' . $speed }{$name} = $breed;
    }
    close $fh or die "Cannot read file: $!";

    return;
}

sub write_reports {

    foreach my $type ( sort keys %pets ) {
        write_report($type);
    }

    return;
}

sub write_report {
    my ($type) = @_;

    # Create the new report
    open my $fh, '>', "report/$type.txt" or die "Cannot write to file: $!";

  SPELL_SET:
    foreach my $spell_set ( sort keys %{ $pets{$type} } ) {

        # skip if there is only one species id for this specific spell
        # combination
        next SPELL_SET if keys %{ $pets{$type}{$spell_set}{"name"} } <= 1;

        # We have multiple species for this spell combination. But if every
        # species has only one breed we skip it.
        my $multipleBreeds = 0;
        foreach my $species ( keys %{ $pets{$type}{$spell_set}{"name"} } ) {
            if ( $pets{$type}{$spell_set}{"name"}{$species} > 1 ) {
                $multipleBreeds = 1;
            }
        }
        next SPELL_SET if $multipleBreeds == 0;

        # The current spell combination can be found on multiple species
        # whose have multiple breeds
        print $fh "[B]$type $spell_set" . '[/B]' . "\n";
        print $fh '[list]' . "\n";

        # We are sorting the breeds by their stats
        foreach my $kS ( reverse sort keys %{ $pets{$type}{$spell_set}{"stat"} } ) {
            print $fh '[*]' . "$kS\n";
            print $fh '[list]' . "\n";

            # Then we sort the pets by their name
            foreach my $kN ( sort keys %{ $pets{$type}{$spell_set}{"stat"}{$kS} } ) {
                print $fh '[*][pet]' . $kN . '[/pet]';
                my $breed     = $pets{$type}{$spell_set}{stat}{$kS}{$kN};
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
                print $fh " $breedName ($breed)\n";
            }
            print $fh '[/list]' . "\n";
        }
        print $fh '[/list]' . "\n";
    }

    close($fh) or die "$!";

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
