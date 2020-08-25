cls
global raw "D:/Dropbox/Research/Uber/Driver_level_analysis/raw_data/drivers"
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"

* Switch to directory containing raw data
cd $raw

 * Declare macros for ease of referring to filenames
local pf Medallion_Drivers_-_Active_
local f1 2017_04_17
local f2 2018_01_08
local f3 2019_03_09
local f4 2020_07_28

* Import CSVs and save as DTAs
forvalues i=1/4 {
	import delimited `pf'`f`i''.csv, varn(1) colr(1:2) clear
	save `f`i''.dta, replace
}

* Load one DTA and append the rest
use `f1'.dta, clear
append using `f2'.dta `f3'.dta `f4'.dta

* Drop duplicates in terms of both license and name
duplicates drop lic name, force

* Convert driver names to lowercase; driver names are lowercase in complaints data
replace name = strlower(name)

* Replace one or more spaces, commas and hyphens with a single space.
local spchar "~ ! @ # $ % ^ & * ( ) _ - + = { } [ ] \ | : ; < > . ? / ' `"
foreach c of loc spchar {
	replace name = subinstr(name, "`c'", " ", .)
}
replace name = stritrim(strtrim(subinstr(name, ",", " ", .)))

* Generate length of name; one with shorter name will be dropped
gen nlength=strlen(name)
order nl, after(lic)
bys lic (nl): keep if _n == _N
duplicates report lic // should be 0 duplicates
drop nl

* Reverse name order from lastfirst to firstlast
split name, g(a)
loc numvars = r(nvars)
forvalues i = 3/`numvars' {
    di "`i'"
	replace name = a2+" "+a`i'
}
replace name = name+" "+a1
replace name = strtrim(stritrim(name))
drop a*

* Convert license to string (it is string in complaints data)
tostring lic, replace
ren lic license

* Remove intermediate dta files
forvalues i=1/4 {
	rm `f`i''.dta
}

* Compress and save
compress
save "$out/1a_drivers_yellow.dta", replace