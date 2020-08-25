cls
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"
use "$out/1c_drivers_clean.dta", clear
gen liclen = strlen(lic)
drop if licl <=6
drop liv base licl
gen lf6 = substr(lic, 1, 6)
gen lf6_last = substr(lic, 7, 1)
sort lf6 lf6_
drop lic
replace name = stritrim(strtrim(name))
replace name = subinstr(name, " ", ",", .) // replace spaces with commas
reshape wide name, i(lf6) j(lf6_) string
gen allname = strtrim(stritrim(name0+" "+name1+" "+name2+" "+name3+" "+ ///
	name4+" "+name5+" "+name6+" "+name7+" "+name8+" "+name9)) /* now two 
different names are separated by spaces while first name and last name within a
single name is separated by a comma */
drop name*
split allname, gen(name) // parse by space, not commas
drop if name2!=""
drop allname name2-name10
foreach v of var name* {
	replace `v' = subinstr(`v', ",", " ", .)
}
ren (lf6 name1) (license name)
replace name = stritrim(strtrim(subinstr(name, ",", " ", .)))
drop if missing(name)
compress
save $out/2a_drivers_trunc.dta, replace