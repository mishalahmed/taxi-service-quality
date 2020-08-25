#!/bin/bash

# Switch to correct directory
raw="/mnt/d/Dropbox/Research/Uber/Driver_level_analysis/raw_data"
out="/mnt/d/Dropbox/Research/Uber/Driver_level_analysis/output_data"

# Check to see EOL for each file
#dos2unix --info=dum "$raw/medallions/Historical_Medallion__Vehicles_-_Authorized_2017_06_19.csv"

# Some of the records have double quotes in some of the fields and commas inside these quotes. These lead to incorrect parsing of the csv files by Stata. Remove these commas inside quotes and then the quotes themselves:
#head -n5 "Historical_Medallion__Vehicles_-_Authorized_2017_06_19.csv" | awk -v RS='"[^"]*"' -v ORS= '{gsub(/,/, " ", RT)}; {print $0 RT}' | sed 's/\"//g' | cut -d, -f1,2,9 > "2017_06_19_medallion.csv"
#awk -v RS='"[^"]*"' -v ORS= '{gsub(/,/, " ", RT)}; {print $0 RT}' "Historical_Medallion__Vehicles_-_Authorized_2017_06_19.csv" | sed 's/\"//g' | cut -d, -f1,2,9 > "2017_06_19_medallion.csv"

#awk -v RS='"[^"]*"' -v ORS= '{gsub(/,/, " ", RT)}; {print $0 RT}' "Medallion__Vehicles_-_Authorized_2020_08_04.csv" | sed 's/\"//g' | cut -d, -f1,2,9 > "2020_08_04_medallion.csv"

cat $raw/medallions/*Authorized* | sort -u -t, -k1,1  | awk -v RS='"[^"]*"' -v ORS= '{gsub(/,/, " ", RT)}; {print $0 RT}' | sed 's/\"//g' | cut -d, -f1,2,9 | awk -F, 'BEGIN{print "license_number,name,medallion_type"} NR > 1 && $1!="License Number" {print}' > "$out/3a_medallions.csv"

echo "It took $SECONDS seconds."