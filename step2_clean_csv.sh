#!/bin/bash

set -e

dos2unix BreedsPerPet.csv > .tmp
cat .tmp > BreedsPerPet.csv
rm -f .tmp

cat -v BreedsPerPet.csv \
| sed \
	-e 's,AlbinoschimM-^Drling,Albino Chimaeraling,' \
	-e 's,SonnensprM-wssling,Sun Sproutling,' \
	-e 's,Wiesentramplerkalb,Meadowstomper Calf,' \
	-e 's,Verfluchte Birmakatze,Cursed Birman,' \
	-e 's,SchrM-wdingers Katze,Widget the Departed,' \
	-e 's,Sonnenfeuerkaliri,Sunfire Kaliri,' \
	-e 's,[ 	]*$,,' \
	-e 's,"inv_misc_fork&amp;knife",inv_misc_fork\&knife,' \
	> BreedsPerPet.csv.tmp

mv BreedsPerPet.csv.tmp BreedsPerPet.csv

echo "OK."
exit 0
