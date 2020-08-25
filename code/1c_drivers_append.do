* Load yellow cab driver data
cls
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"
use "$out/1a_drivers_yellow.dta", clear

* Append FHV driver data to yellow cab driver data
append using "$out/1b_drivers_fhv.dta"
save "$out/1c_drivers_clean.dta", replace

* Save separate dataset containing unique driver names for exact matching
duplicates tag name, gen(dup)
drop if dup>0
save "$out/1c_drivers_unique_names.dta", replace

* Save separate dataset containing soundex for fuzzy matching
gen name_soundex = soundex(name)
gen name_from_driver_file = name
gen li2 = lic
save "$out/1c_drivers_soundex.dta", replace