#!/bin/bash

cd -- "$(dirname -- "$0")" || exit 1

if [[ -s api_key.txt ]]
then
	API_KEY=$(cat api_key.txt)
fi

if [[ -z $API_KEY ]]
then
	echo "ERROR: Need battle.net API key."
	exit 1
fi

for s in $(sed -n -e '2,$p' BreedsPerPet.csv | awk '{print $1}' | sort -nu)
do
	if [[ ! -f "species/$s" ]]
	then
		echo " ==> $s"
		wget --no-check-certificate -o log.txt -O "species/$s" "https://us.api.battle.net/wow/pet/species/${s}?locale=en_US&apikey=${API_KEY}"
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
