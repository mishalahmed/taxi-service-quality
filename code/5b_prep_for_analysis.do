cls

* Load complaints data
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"
use $out/5a_merge_all.dta, clear

* Drop if both lic. no. and name is missing
keep if regexm(name, " ")
keep if lic!="" & name!=""
drop if regexm(name, "&")

* Create variables containing first and last dates of complaints
bys lic: egen fdate = min(date)
bys lic: egen ldate = max(date)
format fd %tdCCYY-NN-DD
format ld %tdCCYY-NN-DD

* Keep relevant variables and then order and sort
keep name lic year fd ld
sort name lic year fd ld
bys name lic year: egen ccount = count(year)
fillin lic year
gen nlength = strlen(name)
bys lic (nl): replace name = name[_N] if name==""
bys lic (fd): replace fd = fd[1] if fd==.
bys lic (ld): replace ld = ld[1] if ld==.
drop _f nl
duplicates drop lic year, force
sort name lic year
replace cc = 0 if missing(cc)
gen cdummy = (cc>0)

* Declare as panel
destring lic, gen(licnum)
xtset licn year

* Compress and save
compress
save $out/5b_prep_for_analysis.dta, replace