***Name: Su Yeon Seo
***Class: Experimental Design & Implementation
***Semester: Spring 2025
***Assignment: Stata 1

clear all
global projdir "C:\Users\suyeo\Desktop\experimental_design\ppol6818-ss4925\week_03\04_assignment\01_data"
cd "$projdir"

*Q1

*Merge student.dta with teacher.dta using primary_teacher
use "q1_data\student.dta", clear
rename primary_teacher teacher
merge m:1 teacher using q1_data\teacher.dta
drop if _merge != 3 // Keep only matched observations
drop _merge

*Merge with school.dta to get school details
merge m:1 school using q1_data\school.dta
drop if _merge != 3 // Keep only matched observations
drop _merge

*Merge with subject.dta to get subject detailes
merge m:1 subject using q1_data\subject.dta


**(a) Mean attendance of students at southern schools
summarize attendance if loc == "South"

**(b) Of all students in high school, what proportion of them 
**have a primary teacher who teaches a tested subject?
summarize tested if level == "High"

**(c) What is the mean gpa of all students in the district?
summarize gpa

**(d) What is the mean attendance of each middle school?
collapse (mean) attendance if level == "Middle", by(level school)
list


*Q2

**(a) Create a new dummy variable(pixel_consistent)
**pixel_consistent =0 if payout var. inconsistent within the pixel
**pixel_consistent =1 if payout var. all exactly the same within the pixel

use "q2_village_pixel.dta", clear

bysort pixel: gen payout0 = (payout == 0)
bysort pixel: egen sumpayout0 = total(payout0)
bysort pixel: gen payout1 = (payout == 1)
bysort pixel: egen sumpayout1 = total(payout1)
gen pixel_consistent = (sumpayout0 == 0 | sumpayout1 == 0)
tab pixel_consistent

**(b) Create a new dummy variable(pixel_village)
**pixel_village =0 if all households from the village are within a particular pixel
**pixel_village =1 if all households from the village are in more than 1 pixel
bysort village: gen numhhid = _N
bysort village pixel: gen numpixel = _N
gen pixel_village = (numhhid != numpixel)
tab pixel_village

**(c) Divide the households in 3 categories
**village_category =1 if villages are entirely in a particular pixel
**village_category =2 if villages are in different pixels & have some payout
**village_category =3 if villages are in different pixels & have different payout
bysort village: gen payout2 = (payout == 0)
bysort village: egen sumpayout2 = total(payout2)
bysort village: gen payout3 = (payout == 1)
bysort village: egen sumpayout3 = total(payout3)
gen village_consistent = (sumpayout2 == 0 | sumpayout3 == 0)
gen village_category = . 
replace village_category = 1 if pixel_village == 0
replace village_category = 2 if pixel_village == 1 & village_consistent == 1
replace village_category = 3 if pixel_village == 1 & village_consistent == 0
tab village_category


*Q3

**generate 5 new columns(var.): (1) stand_r1_score, (2) stand_r2_score, (3) stand_r3_score, (4) average_stand_score, (5) rank
**score normalizing formula: (score-mean)/sd *mean = mean score of each reviewer
**Hint: standardize score based on netID instead of by reviewers
**use reshape
use "q3_proposal_review.dta", clear

rename Rewiewer1 Reviewer1 //rename variable to run a command on Reviewer1,2,3, altogether
rename Review1Score ReviewerScore1 //rename variable to run a command on ReviewerScore1,2,3, altogether
rename Reviewer2Score ReviewerScore2
rename Reviewer3Score ReviewerScore3
reshape long Reviewer ReviewerScore, i(proposal_id) j(round) //change data form from wide to long
bysort Reviewer: egen mean = mean(ReviewerScore) //generate mean by reviewer level 
bysort Reviewer: egen sd = sd(ReviewerScore) // generate sd by reviewer level
gen standardizedscoreR = (ReviewerScore - mean)/sd //generate standardized score by reviewer level
reshape wide Reviewer ReviewerScore mean sd standardizedscoreR, i(proposal_id) j(round)
gen standardizedscoreP = (standardizedscoreR1 +standardizedscoreR2 +standardizedscoreR3)/3 //generate standardized score by proposal level
egen rank = rank(standardizedscoreP) //generate rank
sum rank


*Q4

**extract column 2-13 from the first row ("18 and above") from each table. Create a dataset where each row contains information for a particular district
global wd "C:/Users/suyeo/Desktop/experimental_design/ppol6818-ss4925"
*update the wd global so that it refers to the Box folder filepath on your machine

global excel_t21 "$wd/week_03/04_assignment/01_data/q4_Pakistan_district_table21.xlsx"

clear

*setting up an empty tempfile
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one
	rename TABLE21PAKISTANICITIZEN1 table21

	
	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21' 
	save `table21', replace //saving the tempfile so that we don't lose any data
}
*load the tempfile
use `table21', clear
*fix column width issue so that it's easy to eyeball the data
format %40s table21 B C D E F G H I J K L M N O P Q R S T U V W X Y  Z AA AB AC

save "q4.dta", replace

use "q4.dta", clear

local cols "B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC"

*get rid of -
foreach var in `cols' {
	replace `var' = "" if regexm(`var',"-")
	replace `var' = "" if trim(`var') == ""
}

order table, first
sort table

local i = 1
foreach var of varlist B-Z AA-AC {
	rename `var' value`i'
	local i = `i' + 1
}

reshape long value, i(table) j(No) string

drop if value == ""

drop No // not in incremental order. cannot use for reshaping

bysort table: gen No = _n

reshape wide value, i(table) j(No)

replace table21 = "18 AND ABOVE" if regexm(table21, "OVERALL")


*Q5

**data cleaning & wrangling
**extract the following school level variables: 
**1) number of students that took the test, 
**2) school average 
**3) student group (binary, either under 40 or >=40  
**4) school ranking in council (22 out of 46) 
**5) school ranking in the region (74 out of 290)
**6) school ranking at the national level (545 out of 5664) level dataset with the following variables. 
use "q5_Tz_student_roster_html.dta", clear
display s // help see data that I couldn't see due to invalid extraction
gen school_name = regexs(1) if regexm(s, "([A-Z]+)\s*PRIMARY\s*SCHOOL - [A-Z][A-Z][0-9]{7}")
gen school_code = regexs(1) if regexm(s, "[A-Z]+\s*PRIMARY\s*SCHOOL - ([A-Z][A-Z][0-9]{7})")
gen number_of_student = regexs(1) if regexm(s, "WALIOFANYA\s*MTIHANI\s*: ([0-9]{2})")
gen school_avg = regexs(1) if regexm(s, "WASTANI\s*WA\s*SHULE\s*: ([0-9]{3}\.[0-9]{4})")
gen student_group = 0
replace student_group = 1 if regexm(s, "KUNDI\s*LA\s*SHULE\s*: Wanafunzi\s*chini\s*ya 40")
gen school_ranking_council = regexs(1) if regexm(s, "NAFASI\s*YA\s*SHULE\s*KWENYE\s*KUNDI\s*LAKE\s*KIHALMASHAURI: ([0-9]{2})")
gen school_ranking_region = regexs(1) if regexm(s, "NAFASI\s*YA\s*SHULE\s*KWENYE\s*KUNDI\s*LAKE\s*KIMKOA\s*:\s*([0-9]{2})")
gen school_ranking_national = regexs(1) if regexm(s, "NAFASI\s*YA\s*SHULE\s*KWENYE\s*KUNDI\s*LAKE\s*KITAIFA\s*:\s*([0-9]{3})")