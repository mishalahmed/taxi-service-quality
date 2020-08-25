cls
snapshot erase _all 

* Load data
global out "D:/Dropbox/Research/Uber/Driver_level_analysis/output_data"
use $out/4b_complaints_clean.dta, clear

/* Step 1a: Remove special characters and leading, trailing and multiple internal 
spaces */
local spchar "~ ! @ # $ % ^ & * ( ) _ - + = { } [ ] \ | : ; < > . ? / ' `"
foreach v of var lic name med { 
	replace `v' = strtrim(stritrim(`v'))
	foreach c of local spchar {
			replace `v' = subinstr(`v',"`c'","",.)
	}
}
	
/* Step 1b: Check to see if license numbers or driver names are mistakenly stored in 
'medallion' variable. If yes, we need to extract them. */
replace med = "" if med == "NA"
replace med = strupper(med) /* only 9 instances where letter in medallion number 
was incorrectly not capitalized */
count if regexm(med, "[0-9][A-Z][0-9][0-9]|[A-Z][A-Z][0-9][0-9][0-9]|[A-Z][A-Z][A-Z][0-9][0-9][0-9]")==0 & med!=""
/* None found. The above code checks for 3 formats for medallion numbers. See
below for more info */

/* Step 1c: Remove single or double letter names and license numbers such as 
'a' or '1' and remove numbers that are 5 digits or less. */
foreach v of var name lic {
	replace `v' = strlower(`v') // Convert to lowercase for easier regex matching
	replace `v' = "" if regexm(`v', "^[a-z]?[a-z]?$") & !missing(`v')
	replace `v' = "" if regexm(`v', "^[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?$") & ///
		!missing(`v')
}

/* Step 1d: Split name into namealpha and namenum and split license into 
licalpha and licnum */
local dtype "alpha num"
foreach t of loc dtype {
	split name, gen(`t')
	forvalues i = 1/14 {
		if "`t'" == "alpha" {
			replace `t'`i'="" if regexm(`t'`i', "[0-9]")
		}
		else if "`t'" == "num" {
			replace `t'`i'="" if regexm(`t'`i', "^[a-z]+$")
		}
	}
	gen name`t' = `t'1+" "+`t'2+" "+`t'3+" "+`t'4+" "+`t'5+" "+`t'6+" "+ ///
		`t'7+" "+`t'8+" "+`t'9+" "+`t'10+" "+`t'11+" "+`t'12+" "+`t'13+" "+`t'14
	replace name`t' = strtrim(stritrim(name`t'))
	drop `t'*
	split license, gen(`t')
	forvalues i = 1/12 {
		if "`t'" == "alpha" {
			replace `t'`i'="" if regexm(`t'`i', "[0-9]")
		}
		else if "`t'" == "num" {
			replace `t'`i'="" if regexm(`t'`i', "^[a-z]+$")
		}
	}
	gen lic`t' = `t'1+" "+`t'2+" "+`t'3+" "+`t'4+" "+`t'5+" "+`t'6+" "+`t'7+ ///
	" "+`t'8+" "+`t'9+" "+`t'10+" "+`t'11+" "+`t'12
	replace lic`t' = strtrim(stritrim(lic`t'))
	drop `t'*
}

/* Example complaint that has both letters and numbers in both original name
and license variables. Check to see if split took place correctly. */
list if regexm(name, "james albert")
drop name license // drop original variables after split
snapshot save

/* Step 2a: Extract license numbers from namenum and licnum using license number 
format which is a 6 or 7 digit number with NO alphabetic characters */
foreach v of var *num {
	* 6-digit numbers
	gen licfrom`v'=regexs(2) if regexm(`v', "^(0*)([1-9][0-9][0-9][0-9][0-9][0-9]) (.)*") // beginning
	replace licfrom`v'=regexs(3) if regexm(`v', "(.)* (0*)([1-9][0-9][0-9][0-9][0-9][0-9]) (.)*") // middle
	replace licfrom`v'=regexs(3) if regexm(`v', "(.)* (0*)([1-9][0-9][0-9][0-9][0-9][0-9])$") // end
	replace licfrom`v'=regexs(2) if regexm(`v', "^(0*)([1-9][0-9][0-9][0-9][0-9][0-9])$") // self-contained

	* 7-digit numbers
	replace licfrom`v'=regexs(2) if regexm(`v', "^(0*)([1-9][0-9][0-9][0-9][0-9][0-9]) (.)*") // beginning
	replace licfrom`v'=regexs(3) if regexm(`v', "(.)* (0*)([1-9][1-9][0-9][0-9][0-9][0-9][0-9]) (.)*") // middle
	replace licfrom`v'=regexs(3) if regexm(`v', "(.)* (0*)([1-9][1-9][0-9][0-9][0-9][0-9][0-9])$") // end
	replace licfrom`v'=regexs(2) if regexm(`v', "^(0*)([1-9][1-9][0-9][0-9][0-9][0-9][0-9])$") // self-contained
}
*as licfroml == licfromn if !missing(licfroml,licfromn)
replace licfroml = licfromn if licfroml=="" & licfromn!=""

/* Step 2b: Extract medallion numbers from namenum and licnum using the three
different medallion number formats which are described at the following link:
http://www.nyc.gov/html/tlc_medallion_info/html/tlc_lookup.shtml */

foreach v of var namenum licnum {
	replace `v' = strupper(`v')
	* one number, one letter, two numbers. For example: 5X55
	gen medfrom`v'=regexs(2) if regexm(`v',"(.)*([0-9][A-Z][0-9][0-9])(.)*")
	
	* two letters, three numbers. For example: XX555
	replace medfrom`v'=regexs(2) if regexm(`v',"(.)*([A-Z][A-Z][0-9][0-9][0-9])(.)*")

	* three letters, three numbers. For example: XXX555
	replace medfrom`v'=regexs(2) if regexm(`v',"(.)*([A-Z][A-Z][A-Z][0-9][0-9][0-9])(.)*")
}
*as meda == medfroml if !missing(meda,medfroml)
*as meda == medfromn if !missing(meda,medfromn)
replace meda = medfroml if meda=="" & medfroml!=""
replace meda = medfromn if meda=="" & medfromn!=""

/* Step 2c: Extract livery numbers from namenum and licnum using format 
described at the following link:
https://twitter.com/nyctaxi/status/1129054515112620033
Livery + black cars can be identified by their license plates, which typically 
begin with the letter "T" and end with the letter "C" (unless a vanity plate). */
foreach v of var namenum licnum {
	gen liveryfrom`v'=regexs(2) if regexm(`v',"(.)*(T[0-9][0-9][0-9][0-9][0-9][0-9]C)(.)*")
}
* as liveryfroml == liveryfromn if !missing(liveryfroml,liveryfromn)
replace liveryfroml = liveryfromn if liveryfroml=="" & liveryfromn!=""

* Step 2d: Replace non-names in namealpha and licalpha with missing values
loc cw1 "none|not|dont|didnt|wont|wouldnt|wasnt|couldnt|cant|able|post"
loc cw2 "first|last|name|man|woman|male|female|caller|driver|dispatcher"
loc cw3 "clear|available|sure|refuse|visible|hidden|number|display|tbd|k(n)?ow(n)?|think"
loc cw4 "taxi|uber|lyft|hack|car|cab|yellow|medallion|leasing|lease|transit|transport"
loc cw5 "vehicle|van|licen[cs]e|plate|trip|tlc|credit|debit|card|phone|test"
loc cw6 "l[\. ]*l[\. ]*c\.*|corp|inc|l[\. ]*t[\. ]*d\.*|associate|company"
loc cw7 "author|from|legible|management|picture|photo|identi|claim"
loc cw8 "left|right|front|back|small|writing|obtain|determine|mention|dark|light"
loc cw9 "india|pakistan|bangla|bengal|origin|africa|asia"

foreach v of var *alpha {
	forvalues i = 1/9 {
		di "Now replacing common words `i'"
		replace `v' = "" if regexm(`v', "`cw`i''")
	}
	replace `v' = "" if regexm(`v', "^i?d?k?$")
	replace `v' = "" if regexm(`v', "(crown victoria)|(town car)")
	replace `v' = "" if regexm(`v', "^unk$")
	replace `v' = "" if regexm(`v', "^no$| no |^no | no$")
}
* as namea == lica if !missing(namea,lica)
replace namea = lica if namea=="" & lica!=""
replace namea = "" if regexm(namea, "^[a-z]?[a-z]$") & !missing(`v')

* Step 3: Rename and drop variables and observations and drop duplicates
rename (licfroml liveryfroml namea) (license livery name)
drop *num *alpha
gen name_soundex = soundex(name)
drop if name=="" & lic=="" & meda=="" & liv==""

* Create complaint id
sort date comp meda name lic liv
gen cid = _n
order cid, first

* Compress and save
compress
save $out/4c_complaints_extract.dta, replace