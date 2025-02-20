********************************************************************************
* Econ 4490: Week 1
* Exploring and manipulating data in Stata
* Ali Hamza
* Sep 12th, 2024
********************************************************************************

/*
Topics:


1 Introduction to STATA: directories, import/export datasets in different 
  formats, basic commands to explore datasets, annotation, data cleaning, labels

2 Basic Data Manipulation: generating new variables, if/if else statements, 
  and/or conditions, preserve/restore 
  
3 Missing values, locals, globals, egen, duplicates/isid, loops, string 
functions, and describing data with tab, table
  */
  
set more off
clear
********************************************************************************
*11. MACROS:
******************************************************************************** 


/*
A macro is basically a symbol that you program Stata to read as something else; 
for example, if you tell Stata that X means "Apples", every time Stata sees X it 
knows that you really mean "Apples".
*/


********local Vs Global*************

/*
local:
Local macros are only visible locally, meaning within
the same program, do file, do-file editor contents or interactive
session
*/

/*
global:
Global macros are visible everywhere, or globally, meaning within any program, 
do file, or do-file editor contents and within an interactive session.  
*/

/*
The difference between local and global macros is that local macros are private 
and global macros
are public
*/

*Example

global X "Apples"
display as error "$X"

local X "Apples"
display as red "`X'"



*run line 62 & 63 together and then separately. Notice the difference! 

cd "/Users/ah1152/Desktop/ppol6618/week_03/02_data"


*Example (Global)

	global wd "/Users/ah1152/Desktop/ppol6618"
	*NOTE: Change ^^^THIS^^^
	use "$wd/week_03/02_data/car_insurance", clear

	*OR I can define another global for the dataset:
	clear
	global insurance "$wd/week_03/02_data/car_insurance"
	global project_t "$wd/week_03/02_data/project_t"
	global project_e "$wd/week_03/02_data/project_e"
	global project_educ "$wd/week_03/02_data/project_educ"
	 
	*load insurance data
	use "$insurance", clear
	 
	*load project T data
	use "$project_t", clear
	

*Example (local)

	regress vin1q1_yes treat_makutano treat_mil treat_makutano_amt  treat_mil_amt age_in_years age_square secondaryschool wealth_index employed married television membership election_dummy , cluster(circlecode) 
	
		regress vin1q2_yes treat_makutano treat_mil treat_makutano_amt  treat_mil_amt age_in_years age_square secondaryschool wealth_index employed married television membership election_dummy , cluster(circlecode) 

		
			regress vin1q3_yes treat_makutano treat_mil treat_makutano_amt  treat_mil_amt age_in_years age_square secondaryschool wealth_index employed married television membership election_dummy , cluster(circlecode) 

			
				regress vin1q4_yes treat_makutano treat_mil treat_makutano_amt  treat_mil_amt age_in_years age_square secondaryschool wealth_index employed married television membership election_dummy , cluster(circlecode) 


	****running the same regression useing locals
	*Set locals for independent variables
	local treatment treat_makutano treat_mil treat_makutano_amt  treat_mil_amt
		
	*Set locals for constants
	local controls age_in_years age_square secondaryschool wealth_index ///
		employed married television membership election_dummy
	
	reg vin1q1_yes `treatment' `controls', cluster(circlecode) 


 ********************************************************************************
*12. Loops: foreach & forvalues
********************************************************************************

/*
*foreach:
foreach repeatedly sets local macro lname to each element of the list and executes
the commands enclosed in braces.  The loop is executed zero or more times; it is 
executed zero times if the list is null or empty.
*/

*Example 1:

	foreach alphabet in a b c d e f g h i j k l m n o p q r s t u v x y z {
		display as error "`alphabet'"
			}
*
*Example 2:



	use "$project_t", clear
	*add "b_" prefix 
	foreach x in circlecode treatment age_in_years treat_makutano treat_mil ///
	treat_makutano_amt treat_mil_amt age_square secondaryschool wealth_index employed ///
	 married television membership election_dummy vin1q1_yes vin1q2_yes vin1q3_yes ///
	 vin1q4_yes {
		rename `x' b_`x'
			}
*	 
	 *using wildcard options
	 use "$project_t", clear
	 foreach x in * {
		rename `x' b_`x'
			}
*	 
*Example 3:
use "$project_t", clear


		*Set locals for independent variables
		local treatment treat_makutano treat_mil treat_makutano_amt  treat_mil_amt
			
		*Set locals for constants
		local controls age_in_years age_square secondaryschool wealth_index ///
			employed married television membership election_dummy
	local i =1
	foreach dep_var in vin1q1_yes vin1q2_yes vin1q3_yes vin1q4_yes{

	display as error "This is iteration `i'"	
	display 	"reg `dep_var' `treatment' `controls', cluster(circlecode)" 
	local i = `i' +1
	}
*


/*
forvalues:
forvalues repeatedly sets local macro lname to each element of range and executes
the commands enclosed in braces.  The loop is executed zero or more times.
*/

*Example 1:
	forvalues i=1/20{
		display `i'
			}
*

*Example 2:
	forvalues i=1 (2) 20{
		display `i'
			}
*
 
*Example 3 (calculating duration for each insurance plan
use "$insurance", clear
gen	policy_duration1 = expirydate1 - startdate1
gen	policy_duration2 = expirydate2 - startdate2
gen	policy_duration3 = expirydate3 - startdate3
gen	policy_duration4 = expirydate4 - startdate4
gen	policy_duration5 = expirydate5 - startdate5




/*
	"RULE OF THREE" (code duplication)
"You are allowed to copy and paste the code once, but that when the same code is 
replicated three times, it should be extracted into a new procedure.

Duplication in programming is almost always in indication of poorly designed 
code or poor coding habits. Duplication is a bad practice because it makes code 
harder to maintain." 
*/

*We can use forvalues loop to generate these 5 variables
use "$insurance", clear
*How?



********************************************************************************
*13. Indexing: Referring to observations, keeping, and dropping obs :
********************************************************************************

* _n refers to the number of the row 
use "$insurance", clear
gen obsnum=_n 
lab var obsnum "Observation number" 
order obsnum, first 


* writing _n refers to observations 
list if _n<50 //will browse the first 49 observations 

*dropping and keeping 
drop if _n>1000 
keep if _n<=100 //will keep the first 100 observatiosn 

*you can refer to certain values of variables in certain observations 

use "$insurance", clear

sort reg_marks
gen duplicate_reg=0
replace duplicate_reg=1 if  reg_marks[_n]==reg_marks[_n+1]
replace duplicate_reg=1 if  reg_marks[_n]==reg_marks[_n-1]


********************************************************************************
*14. egen (Extensions to generate)
********************************************************************************

use "$project_e", clear

gen total_score = (math_score + eng_score)


*mean
egen mean = mean(total_score)

*min
egen min = min(total_score)
*max
egen max = max(total_score)

*median
egen median = median(total_score)



********************************************************************************
*15. bysort
********************************************************************************

/*
It repeats the command for each group of observations for which the values of 
the variables in varlist are the same.
*/

use "$project_e", clear


bysort schoolcode: gen serial = _n
gen total_score = (math_score + eng_score)

*calculate mean, median, min, max for each school

*mean
bysort schoolcode: egen score_mean = mean(total_score)

*min
bysort schoolcode: egen score_min = min(total_score)
*max
bysort schoolcode: egen score_max = max(total_score)

*median
bysort schoolcode: egen score_median = median(total_score)


*generate a dummy variable where it's 1 for only 1 observation within a distinct group (school in this case)

egen tag_var = tag(schoolcode) 
keep if tag_var==1


********************************************************************************
*16. recode, destring, encode, decode
********************************************************************************
use "$project_educ", clear

/*
Recode: 
It changes the values of numeric variables according to the rules specified. 
*/

*we have a dummy variable for male but we want to include a dummy variable female
*in our regression model. Using recode option

gen female=male
recode female (1=0) (0=1) 
tab male female

/*detring
It converts variables in varlist from string to numeric
*/

*age is a string vartiable 
destring(age), replace


gen female2 = female 
label define fgender 1 "Female" 0 "Male" //gender is the name of the value label
label values female2 "fgender" //here the variable is called female. 

decode female2, gen(gender)
encode gender, gen(female3)


********************************************************************************
* 17. Datasets commands: merge, append, reshape, cf 
********************************************************************************

/*
*merge
 merge joins corresponding observations from the dataset currently in memory 
 (called the master dataset) with those from filename.dta (called the using 
 dataset), matching on one or more key variables.  merge can perform match
 merges (one-to-one, one-to-many, many-to-one, and many-to-many), which are 
 often called 'joins' by database people.
 */


global baseline "$wd/week_03/02_data/project_educ_baseline.dta"
global endline "$wd/week_03/02_data/project_educ_endline.dta"

use "$baseline", clear

merge 1:1 student_id using "$endline"

*look at m:1, 1:m & m:m option

/*
Append:
append appends Stata-format datasets stored on disk to the end of the dataset 
in memory. 
*/

use "$baseline", clear

append using "$endline"
sort student_id

bysort student_id: egen baseline_score = max(total_M_B)
bysort student_id: egen endline_score = max(total_M_E)

drop total*


/*
reshape
It converts data from wide to long form and vice versa.
*/

*wide to long
webuse reshape1, clear
reshape long inc ue, i(id) j(year)


*long to wide
 reshape wide inc ue, i(id) j(year)
 

********************************************************************************
*18. INTEROPERABILITY: c-class variables
********************************************************************************

/*
c-class values:
they are designed to provide one all-encompassing way to access system parameters
and settings, including system directories, system limits etc
*/

*Example
creturn list

*Objective: You should be able to run my do file without changing a single line 
*			of code

*Solution: You can do this using c(username) & if/else statements:

 
 
********************************************************************************
*19. Preserve/Restore. tempfiles
********************************************************************************




 
********************************************************************************
*20. String functions
********************************************************************************
/*
*split

*substr
					substr("abcdef",2,3) = "bcd"
                     substr("abcdef",-3,2) = "de"
                     substr("abcdef",2,.) = "bcdef"
                     substr("abcdef",-3,.) = "def"
                     substr("abcdef",2,0) = ""
                     substr("abcdef",15,2) = ""

*subinstr
					 subinstr("this is the day","is","X",1) = "thX is the day"
                     subinstr("this is the hour","is","X",2) = "thX X the hour"
                     subinstr("this is this","is","X",.) = "thX X thX"


*strpos 
					 strpos("this","is") = 3
					 
*strlen 
					 strlen("ab") = 2



*/



/*
regexm(s,re)
performs a match of a regular expression and evaluates to 1 if regular 
expression re is satisfied by the ASCII string s; otherwise, 0
*/


*Example1:
global project_u "$wd/week_03/02_data/project_u.dta"
use "$project_u", clear

*correct answer is 7:25 am for mq10

gen mq10_new =""
replace mq10_new = "7:25am" if regexm(mq10,"7:25")
replace mq10_new = "7:25am" if regexm(mq10,"7hrs")
replace mq10_new = "7:25am" if regexm(mq10,"7.25") | regexm(mq10,"725")
replace mq10_new = "" if regexm(mq10,"pm")
replace mq10_new = "" if regexm(mq10,"p.m")
*example:


*Example2:
global project_treg "$wd/week_03/02_data/project_treg.dta" 
use "$project_treg", clear

*registration number for vehicles registered in Tanzania should look like:
* regnum = T123ABC
gen correct_regnum = regexm(regnum,"^T[0-9][0-9][0-9][A-Z][A-Z][A-Z]$")
