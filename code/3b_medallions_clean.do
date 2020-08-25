cls
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"

* Switch to directory containing raw data
cd $out

* Import csv
import delim 3a_medallions.csv, varn(1) clear

* Rename variables and change variable type
encode med, gen(medtype)
drop meda
rename (lic name) (medallion medowner)

* Remove blanks and special characters and convert to lowercase
replace medo = strlower(strtrim(stritrim(medo)))
local spchar "~ ! @ # $ % ^ * ( ) _ - + = { } [ ] \ | : ; < > . ? / ' `"
foreach c of loc spchar {
	replace medo = subinstr(medo, "`c'", " ", .)
}

* Remove names for medallions with multiple owners
local corp " l[\. ]*l[\. ]*c\.*| corp| taxi| inc| l[\. ]*t[\. ]*d\.*| cab| transit| associate|motor"
drop if regexm(medo, "`corp'")

* Reverse name order from lastfirst to firstlast
split medo, p("&" " and ")
foreach v of var medowner1 medowner2 {
	split `v', g(n)
	replace `v' = strtrim(stritrim(n2+" "+n3+" "+n1))
	drop n*
}
drop medowner medowner2 medowner3
ren medowner1 name // this is for merging only

/* Drop duplicate names. Note: this is for merging only. In reality, these may 
well be different people with the same name or the same person driving for 
different medallion numbers. But without further information, there is no way to 
uniquely identify them. */
duplicates tag name, gen(dup)
drop if dup>0

* Compress and save
compress
save "3b_medallions_clean.dta", replace