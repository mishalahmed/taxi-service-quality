* Load complaints data
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"
use $out/4c_complaints_extract.dta, clear

gen month = month(date)
gen year = year(date)

pr drop _all
pr mergedriver
* Create intermediate variables (to be dropped later)
gen nlength = strlen(name)
gen llength = strlen(lic)
gen lvlength = strlen(liv)

* Merge with driver and medallion data
mer m:1 lic using $out/1c_drivers_clean.dta, keep(1 3 4 5) update replace nogen
mer m:1 name using $out/3b_medallions_clean.dta, keep(1 3 4 5) update nogen

* Merge with driver data using exact unique names
mer m:1 name using $out/1c_drivers_unique_names.dta, keep(1 3 4 5) update replace nogen

* Merge with driver data using similar unique names
loc cond "name!=name_f & name!="" & name_f!="" & lic=="" & regexm(name, " ")"
mer m:m name_soundex using $out/1c_drivers_soundex.dta, keep(1 3) nogen

* Levenshtein
strdist name name_f, gen(fuzzylev)
replace name = name_f if fuzzylev<=2 & `cond'

* Jaro-Winkler
jarowinkler name name_f, gen(fuzzyjw)
replace name = name_f if fuzzyjw>=0.95 & `cond'

* n-gram similarity
matchit name name_f, gen(fuzzysim) sim(ngram_circ, 2)
replace name = name_f if fuzzysim>=0.8 & `cond'

drop fuz*
duplicates drop cid, force

/* For same license number, copy name and livery no. from one complaint to 
another if one or more is missing */
bys lic (nl): replace name = name[_N] if name=="" & name[_N]!="" & lic!=""
bys lic (lv): replace liv = liv[_N] if liv=="" & liv[_N]!="" & lic!=""

/* For same livery number, copy name and lic. no. from one complaint to 
another if one or more is missing */
bys liv (nl): replace name = name[_N] if name=="" & name[_N]!="" & liv!=""
bys liv (ll): replace lic = lic[_N] if lic=="" & lic[_N]!="" & liv!=""

/* For same name and medallion number, copy lic. no. and liv no. from one 
complaint to another if one or more is missing */
bys meda name (ll): replace lic = lic[_N] if lic=="" & lic[_N]!="" & ///
	meda!="" & name!=""
bys meda name (lv): replace liv = liv[_N] if liv=="" & liv[_N]!="" & ///
	meda!="" & name!=""

/* For same name and date, copy lic. no. and livery no. from one complaint 
to another if one or more is missing */
bys name date (ll): replace lic = lic[_N] if lic=="" & lic[_N]!="" & name!=""
bys name date (lv): replace liv = liv[_N] if liv=="" & liv[_N]!="" & name!=""

/* For same name, year and month, copy lic. no. and livery no. from one 
complaint to another if one or more is missing */
bys name year month (ll): replace lic = lic[_N] if lic=="" & lic[_N]!="" & name!=""
bys name year month (lv): replace liv = liv[_N] if liv=="" & liv[_N]!="" & name!=""

/* For same name (of sufficiently long length), copy lic. no. and livery 
no. from one complaint to another if one or more is missing */
bys name (ll): replace lic = lic[_N] if lic=="" & lic[_N]!="" & regexm(name, " ")
bys name (lv): replace liv = liv[_N] if liv=="" & liv[_N]!="" & regexm(name, " ")

/* Some lic. no. are truncated. Match with truncated versions in the
driver dataset. */
mer m:1 license using $out/2a_drivers_trunc.dta, keep(1 3 4 5) update nogen
mer m:1 license using $out/2b_drivers_trunc.dta, keep(1 3 4 5) update nogen

/* Put in code to replace license numbers when one complaint has 6 digit
number and another has 7 digits for the same name and the 6 digits form
part of the 7 digits. For an example, see "mahmudul alam, 5232147" */

drop nl ll lv
end

qui cou if name!=""
loc namenm0 = r(N)
qui cou if lic!=""
loc licnm0 = r(N)
loc totnm0 = `namenm0' + `licnm0'
di "`totnm0'"
loc i = 0
loc j = 1
loc totupd = 1

while `totupd' > 0 {
    mergedriver
	qui cou if name!=""
	loc namenm`j' = r(N)
	loc nameupd`j' = `namenm`j'' - `namenm`i''
	di "`nameupd`j'' names were updated in Round `j'"
	qui cou if lic!=""
	loc licnm`j' = r(N)
	loc licupd`j' = `licnm`j'' - `licnm`i''
	di "`licupd`j'' lic. no. were updated in Round `j'"
	loc totupd = `nameupd`j'' + `licupd`j''
	loc i = `i' + 1
	loc j = `j' + 1
}

* Compress and save
compress
save $out/5a_merge_all.dta, replace