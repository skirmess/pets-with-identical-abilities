#!/bin/bash

set -e

cd -- "$(dirname -- "$0")"

awk -F';' '{print $1, $4}' BreedsPerPet.csv | \
sort -n -u | \
grep '^[1-9]' | \
sed \
	-e 's,  ,] = ",' \
	-e 's,^,  petSpecies[,' \
	-e 's,$,";,' \
	-e 's,  \(petSpecies\[92\]\),  //\1,' \
	-e 's,  \(petSpecies\[93\]\),  //\1,' \
	-e 's,  \(petSpecies\[94\]\),  //\1,' \
	-e 's,  \(petSpecies\[107\]\),  //\1,' \
	-e 's,  \(petSpecies\[111\]\),  //\1,' \
	-e 's,  \(petSpecies\[121\]\),  //\1,' \
	-e 's,  \(petSpecies\[124\]\),  //\1,' \
	-e 's,  \(petSpecies\[131\]\),  //\1,' \
	-e 's,  \(petSpecies\[155\]\),  //\1,' \
	-e 's,  \(petSpecies\[170\]\),  //\1,' \
	-e 's,  \(petSpecies\[171\]\),  //\1,' \
	-e 's,  \(petSpecies\[179\]\),  //\1,' \
	-e 's,  \(petSpecies\[180\]\),  //\1,' \
	-e 's,  \(petSpecies\[188\]\),  //\1,' \
	-e 's,  \(petSpecies\[189\]\),  //\1,' \
	-e 's,  \(petSpecies\[217\]\),  //\1,' \
	-e 's,  \(petSpecies\[228\]\),  //\1,' \
	-e 's,  \(petSpecies\[231\]\),  //\1,' \
	-e 's,  \(petSpecies\[240\]\),  //\1,' \
	-e 's,  \(petSpecies\[245\]\),  //\1,' \
	-e 's,  \(petSpecies\[246\]\),  //\1,' \
	-e 's,  \(petSpecies\[247\]\),  //\1,' \
	-e 's,  \(petSpecies\[248\]\),  //\1,' \
	-e 's,  \(petSpecies\[249\]\),  //\1,' \
	-e 's,  \(petSpecies\[256\]\),  //\1,' \
	-e 's,  \(petSpecies\[258\]\),  //\1,' \
	-e 's,  \(petSpecies\[268\]\),  //\1,' \
	-e 's,  \(petSpecies\[294\]\),  //\1,' \
	-e 's,  \(petSpecies\[297\]\),  //\1,' \
	-e 's,  \(petSpecies\[316\]\),  //\1,' \
	-e 's,  \(petSpecies\[329\]\),  //\1,' \
	-e 's,  \(petSpecies\[346\]\),  //\1,' \
	-e 's,  \(petSpecies\[347\]\),  //\1,' \
	-e 's,  \(petSpecies\[671\]\),  //\1,' \
	-e 's,  \(petSpecies\[757\]\),  //\1,' \
	-e 's,  \(petSpecies\[758\]\),  //\1,' \
	-e 's,  \(petSpecies\[903\]\),  //\1,' \
	-e 's,  \(petSpecies\[1073\]\),  //\1,' \
	-e 's,  \(petSpecies\[1117\]\),  //\1,' \
	-e 's,  \(petSpecies\[1127\]\),  //\1,' \
	-e 's,  \(petSpecies\[1168\]\),  //\1,' \
	-e 's,  \(petSpecies\[1248\]\),  //\1,' \
	-e 's,  \(petSpecies\[1363\]\),  //\1,' \
	-e 's,  \(petSpecies\[1364\]\),  //\1,' \
	-e 's,  \(petSpecies\[1365\]\),  //\1,' \
	-e 's,  \(petSpecies\[1386\]\),  //\1,' \
	-e 's,  \(petSpecies\[1602\]\),  //\1,' \
	-e 's,  \(petSpecies\[1603\]\),  //\1,' \
	> petSpecies.txt

