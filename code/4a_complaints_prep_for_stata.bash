#!/bin/bash

# Switch to correct directory
raw="/mnt/d/Dropbox/Research/Uber/Driver_level_analysis/raw_data/complaints"
out="/mnt/d/Dropbox/Research/Uber/Driver_level_analysis/output_data"

# Bash commands tend to overwrite files. Copy raw data to output folder as a safety measure and then work on copied data.
cp $raw/TLC*.csv $out
cd $out

# Change DOS and Mac line endings to Unix line endings
for f in TLC*.csv; do
	mac2unix ${f}
	dos2unix ${f}
done

# Create file containing header with variable names
head -n1 TLC_2010_2011.csv > header.csv

# Some of the complaints have double quotes in some of the fields and newline characters (\n or \r) inside these quotes. These lead to incorrect parsing of the csv files by Stata. To remove these newline characters inside quotes, but not the ones at the end of each record, use the following code. Note this is one use case where Stata would struggle, since it would parse incorrectly to begin with.
for f in TLC*.csv; do
	awk -F, 'NR>1' ${f} | awk -v RS='"[^"]*"' -v ORS= '{gsub(/\n/, " ", RT)}; {gsub(/\r/, " ", RT)}; {gsub(/\r\n/, " ", RT)}; {gsub(/,/, " ", RT)}; {print $0 RT}' | sed 's/\"//g' > ${f%.*}_prepped.csv
done

# Files for 2011-12, 2012-13 and 2013-2014 contain an extra column (the very first column before zip). This needs to be removed.
for f in TLC_2011_2012_prepped.csv TLC_2012_2013_prepped.csv TLC_2013_2014_prepped.csv; do
	cut -d, -f2- ${f} > col1drop_${f%.*}.csv
	rm $f
done

# Combine the files and then drop the intermediate files
cat header.csv *prepped.csv > 4a_complaints.csv
rm *TLC*.csv header.csv