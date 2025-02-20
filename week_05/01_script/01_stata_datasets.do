*******************************************************************************
* PPOL 6818: Week 05
* Handling datasets in Stata
* Ali Hamza
* Feb 12th, 2025
********************************************************************************
clear 
set seed 1
set more off
********************************************************************************

global wd "C:\Users\suyeo\Desktop\experimental_design\ppol6818-ss4925"

*Working Directory

*Datasets
global tz_elec_15_raw "$wd/week_05/02_data/Tanzania_election_2015_raw.dta"
global tz_elec_15_clean "$wd/week_05/02_data/Tz_elec_15_clean.dta"
global tz_elec_10_clean "$wd/week_05/02_data/Tz_elec_10_clean.dta"
global tz_15_10_gis "$wd/week_05/02_data/Tz_GIS_2015_2010_intersection.dta"

global store_location "$wd/week_05/02_data/store_location_bufferzone.dta"

global kenya_baseline "$wd/week_05/02_data/kenya_education_baseline.dta"
global kenya_endline  "$wd/week_05/02_data/kenya_education_endline.dta"

global phonesurvey "$wd/week_05/02_data/phonesurvey_rename_issue.dta"


/********************************************************************************
*Stata Cheat Sheets
********************************************************************************

https://www.stata.com/bookstore/statacheatsheets.pdf


********************************************************************************/





********************************************************************************
*Merge
********************************************************************************

*Merge 1:1 example Baseline/endline

use "$kenya_baseline",clear
merge 1:1 pseudo_idvar using "$kenya_endline"



use "$kenya_endline",clear
merge 1:1 pseudo_idvar using "$kenya_baseline"

*Is this the same?
 

********************************************************************************
*Fillin
********************************************************************************
webuse fillin1, clear
list
fillin sex race age_group
list

********************************************************************************
*Joinby Vs Cross
********************************************************************************

*Difference between Joinby and Cross

clear

// CREATE "MASTER" DATA SET
set obs 6
gen int id = ceil(_n/3)
gen x = round(runiform()*10,1)
list, clean
tempfile master
save `master'

// CREATE "USING" DATA SET
clear
set obs 6
gen int id = ceil(_n/3)
gen y = round(runiform()*10,1)
list, clean
tempfile using
save `using'


*Use Cross
use `master', clear
rename id id_master
cross using `using'
count
assert `r(N)' == 36
list, clean


**Use Joinby 
use `master', clear
joinby id using `using'
count
assert `r(N)' == 18
list, clean


*example: Buffer Zone Calculations: calculate the number of stores within 500 meters of each store? 
use "$store_location", clear
*in class demo
rename = cross_* // create a new column to enable proper merging: if have identical id variable in master and using data, going to overwrite
tempfile forcross
save 'forcross'

*gen every possible combination of shop 1
use "$store_location", clear

cross using 'forcross'

drop if uniquie_id ==cross_unique_id //dropping self pair : shop 1 * shop 1

sse install geodist //install package to calculate distance
geodist gpsLatitude gpsLongtitude lat_shopone long_shopone, generate(distance) //gen distance variable
gen buffer_shopone =0 // distance variable empty
replace buffer_shopone =1 if distance<= 0.5
// fill in distance variable with calculated distance
tab buffer_shopone

bysort uniquie_id: egen total_shops_inbuffer = total(buffer_shopone)

egen tag_shop = tag(uniquie_id) // reduce the number of observations to shop level\
keep if tag_shop ==1

********************************************************************************
*cf (comparing datasets)// useful if have millions of observations to compare
********************************************************************************
use "$tz_elec_10_clean", clear

*replace ward name where ward_id ==77
replace ward_10 = "WASHINGTON DC" if ward_id_10==77
tempfile edited_data
save `edited_data'// created a tempfile to be able to compare with the original data

use "$tz_elec_10_clean", clear

cf _all using `edited_data' // compare the tempfile data and original data


 
********************************************************************************
*Reclink2 (assignment)
********************************************************************************

/*
use "$tz_15_10_gis", clear 

keep region_gis_2017 district_gis_2017 ward_gis_2017
duplicates drop 
rename (region_gis_2017 district_gis_2017 ward_gis_2017) (region district ward)
sort region district ward
gen dist_id = _n

tempfile gis_15
save `gis_15'


use "$tz_elec_15_clean", clear 
keep region_15 district_15 ward_15
duplicates drop
rename (region_15 district_15 ward_15) (region district ward)
sort region district ward
gen idvar = _n


reclink2 region district ward using `gis_15', idmaster(idvar) idusing(dist_id) gen(score) 
*/ 
 

********************************************************************************
* Dates
********************************************************************************


/* 
https://www.stata.com/manuals13/u24.pdf
 */
 
 
 
 
 
 
 
******************************************************************************** 
*IN class Demos:

*Example 1
use "$phonesurvey", clear

foreach var of varlist * {
	display "var"
	
	local label_value = 'var'[1]// select a specific row(first) and save it locally
	local var_value = 'var'[2]
	
	
	label variable 'var' "label_value"
	rename 'var' var_value
	
}

exit

*Example 2
*example Tanzania 2015 election
use "$tz_elec_15_raw", clear
*in class demo
