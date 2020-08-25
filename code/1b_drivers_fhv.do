cls
global raw "D:/Dropbox/Research/Uber/Driver_level_analysis/raw_data/drivers"
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"

* Load data
import delim "$raw/For_Hire_Vehicles__FHV__-_Active_2020_07_28.csv", varn(1) clear

* Drop Uber and Lyft drivers
drop if regexm(website, "UBER|LYFT")

* Keep needed variables
keep name dmv vehiclel basenum
rename (veh dmv base) (license livery base)

* Convert driver names to lowercase; driver names are lowercase in complaints data
replace name = strlower(name)

* Replace one or more spaces, commas and hyphens with a single space.
local spchar "- , ."
foreach c of loc spchar {
	replace name = subinstr(name, "`c'", " ", .)
}
replace name = stritrim(strtrim(subinstr(name, ",", " ", .)))
replace name="" if regexm(name, "transport|leasing|lease|inc|livery|llc")

* Reverse name order from lastfirst to firstlast
split name, g(a)
loc numvars = r(nvars)
forvalues i = 3/`numvars' {
	replace name = a2+" "+a`i'
}
replace name = name+" "+a1
replace name = strtrim(stritrim(name))
drop a*

* Check for duplicates
duplicates report

* Compress and save
compress
save "$out/1b_drivers_fhv.dta", replace