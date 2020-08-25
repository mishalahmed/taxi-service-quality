cls
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"
use $out/1c_drivers_clean.dta, clear
gen liclen = strlen(lic)
drop if licl <=6
drop liv base licl
drop if substr(lic, 2, 1) == "0"
gen ll6 = substr(lic, 2, 6)
gen ll6_first = substr(lic, 1, 1)
sort ll6 ll6_
drop lic
reshape wide name, i(ll6) j(ll6_) string
ren (ll6 name5) (license name)
drop if missing(name)
compress
save $out/2b_drivers_trunc.dta, replace