cls

* Import CSV and save as DTA file
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"
import delimited $out/4a_complaints.csv, varn(1) clear

* Convert labels to lowercase
foreach v of var * {
	local upper : var label `v'
	local lower = strlower("`upper'")
	label var `v' "`lower'"  
}

** Drop if all values are missing
* First, replace string variables with missing values if containing just spaces
ds, has(type string) 
foreach v in `r(varlist)' { 
	replace `v' = "" if trim(`v') == "" 
}
* Generate variable containing number of non-missing values in each observation
egen nmcount = rownonmiss(_all), strok
* Drop observation if this variable is 0
drop if nmcount == 0
* Drop intermediate variable
drop nmcount

* Drop duplicates in terms of date, des1, incident lat. and long.
duplicates drop date descriptor_1 incident_x incident_y, force

/* Drop if all five variables (date, des1, descriptor_ 2, incident lat. 
and long.) are missing */
keep if date!="" & descriptor_1!="" & descriptor_2!="" & incident_x!="" & ///
	incident_y!=""

* Keep variables that are needed; drop the rest
rename (lic dri med incident_x incident_y descriptor_1 descriptor_2) ///
	(license name medallion longitude latitude cat complaint)
keep date cat comp lic name med

* Create date variable from 'date' string
gen date=date(date, "DMY", 2020)
format date %tdCCYY-NN-DD // format date into readable format
drop date_ // remove 'date' string

* Drop complaints before 2013
drop if year(date)<2010 | year(date)>2017

* Order variables for ease of reference
order date, first
order cat comp, after(med)

/* Standardize des1 categories. Upon investigation of categories not related to
'lost property', the following other categories most likely relate to complaints
against drivers and hence should be renamed to 'Driver Complaint' */
local categ ""Driver Report" "Equipment Complaint" "Vehicle Complaint" "Vehicle Report""
foreach l of loc categ {
	tab comp if cat == "`l'"
	replace cat = "Driver Complaint" if cat == "`l'"
}
keep if cat == "Driver Complaint"
drop cat

/* The following code is only necessary if we are interested in investigating
lost property reports */
/* replace des1 = "Lost Property" if des1 == "Electronics/Phones" | ///
	des1 == "Bag/Wallet" | des1 == "Clothing/Glasses" | ///
	des1 == "Jewelry" | des1 == "Book/Stationery" | ///
	des1 == "Sports Equipment" | des1 == "Musical Instrument" | ///
	des1 == "Other" */
	
* Compress and save
compress
save $out/4b_complaints_clean.dta, replace