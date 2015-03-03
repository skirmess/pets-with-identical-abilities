#!/bin/bash

for s in $(sed -n -e '2,$p' BreedsPerPet.csv | awk '{print $1}' | sort -nu)
do
	if [[ ! -f "species/$s" ]]
	then
		echo " ==> $s"
		wget -o log.txt -O "species/$s" "http://us.battle.net/api/wow/battlePet/species/$s"
		if [[ $? -ne 0 ]]
		then
			cat log.txt
			exit 1
		fi
	fi
done

rm -f log.txt

diff -u <(sed -n -e '2,$p' BreedsPerPet.csv | awk -F';' '{print $1,$4}' | sed -e 's,  *, ,g' | sort -u) <(./step3_download_species_lib.pl | sort)

echo "OK."
exit 0
