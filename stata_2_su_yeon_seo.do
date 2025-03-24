/*
Class: PPOL_6818
Student: Su Yeon Seo
Net ID: ss4925
Deliverable: Stata 2
*/


* Set Working Directory
if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="suyeo" { //this would be your username on your computer
	
	global wd "C:\Users\suyeo\Desktop\ppol_6818" //this would your ppol_6818 folder address
}


****Q1****
/*
1. Objective
   Clean, structure student-level data from messy, web-scraped HTML content in the PSLE Data. Ensure each student's ID, name, gender, grades, school information are properly recorded.
2. Strategy
   Use Pattern Matching   
*/

* Load Data
use "q1_psle_student_raw.dta", clear

* Initialize variables for extracted student details
gen student_num = ""
gen school_code = ""
gen cand_id = ""
gen gender = ""
gen prem_number = "" 
gen name = "" 
gen Kiswahili = "" 
gen English = "" 
gen maarifa = "" 
gen hisabati = "" 
gen science = "" 
gen uraia = "" 
gen average = ""

* Ensure `s` column is stored as a string for regex operations
tostring s, replace force
save "student.dta", replace

* Setting up an empty temporary file to store extracted student records
clear
tempfile student
save `student', replace emptyok

* Reload the dataset
use "student.dta", replace

* Identify unique school codes
levelsof schoolcode, local(schools)

* Loop through each school
foreach school in `schools' {
    preserve
    * Keep data only for the current school
    keep if schoolcode == "`school'"

    * Extract the number of students in the school
    replace student_num = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)$")
    destring student_num, replace force
    local values = student_num[1]  // Store the student count for iteration
    
    display "`values'" 
    display schoolcode
    save "schools.dta", replace

    * Loop through each student in the school
    forvalues i = 1/`values' {
        use "schools.dta", clear
        
        * Extract key student details using regex
        replace school_code = regexs(1) if regexm(s, "([A-Z][A-Z][0-9]{7})$")
        local varcode = school_code[1]

        replace cand_id = regexs(1) if regexm(s, "(PS[0-9]{7}\-[0-9]{4})")
        local varcand = cand_id[1]
        replace s = subinstr(s, "`varcand'", "", 1)

        replace gender = regexs(1) if regexm(s, ">([MF])</FONT>")
        local vargend = gender[1]
        replace s = subinstr(s, ">`vargend'</FONT>", "", 1)

        replace prem_number = regexs(1) if regexm(s, "(2015[0-9]{7})")
        local varprem = prem_number[1]
        replace s = subinstr(s, "`varprem'", "", 1)

        replace name = regexs(1) if regexm(s, "<P>([A-Z]+ [A-Z]+ [A-Z]+)</FONT>")
        local varname = name[1]
        replace s = subinstr(s, "`varname'", "", 1)

        * Extract subject grades
        replace Kiswahili = regexs(1) if regexm(s, "Kiswahili - ([A-Z]),")
        local varKiswahili = Kiswahili[1]
        replace s = subinstr(s, "Kiswahili - `varKiswahili'", "", 1)

        replace English = regexs(1) if regexm(s, "English - ([A-Z]),")
        local varEnglish = English[1]
        replace s = subinstr(s, "English - `varEnglish'", "", 1)

        replace maarifa = regexs(1) if regexm(s, "Maarifa - ([A-Z]),")
        local varmaarifa = maarifa[1]
        replace s = subinstr(s, "Maarifa - `varmaarifa'", "", 1)

        replace hisabati = regexs(1) if regexm(s, "Hisabati - ([A-Z]),")
        local varhisabati = hisabati[1]
        replace s = subinstr(s, "Hisabati - `varhisabati'", "", 1)

        replace science = regexs(1) if regexm(s, "Science - ([A-Z]),")
        local varscience = science[1]
        replace s = subinstr(s, "Science - `varscience'", "", 1)

        replace uraia = regexs(1) if regexm(s, "Uraia - ([A-Z]),")
        local varuraia = uraia[1]
        replace s = subinstr(s, "Uraia - `varuraia'", "", 1)

        replace average = regexs(1) if regexm(s, "Average Grade - ([A-Z])")
        local varaverage = average[1]
        replace s = subinstr(s, "Average Grade - `varaverage'", "", 1)	

        save "schools.dta", replace

        * Create a new dataset with extracted values
        clear
        set obs 1  // Create a single-row dataset

        * Assign extracted values to new variables
        gen school_code = "`varcode'"
        gen cand_id = "`varcand'"
        gen gender = "`vargend'"
        gen prem_number = "`varprem'"
        gen name = "`varname'"
        gen Kiswahili = "`varKiswahili'"
        gen English = "`varEnglish'"
        gen maarifa = "`varmaarifa'"
        gen hisabati = "`varhisabati'"
        gen science = "`varscience'"
        gen uraia = "`varuraia'"
        gen average = "`varaverage'"

        * Append the extracted row to the student dataset
        append using `student'
        save `student', replace
    }
    restore
}

* Load the final cleaned dataset
use `student', clear
sort school_code cand_id
save "data/q1_cleaned.dta", replace



****Q2****
/*
1. Objective
 (1) Merge 2 distinct datasets - (a) Household Data - dta, (b) Population Density Data - xlsx
 (2) Add an additional column, "population_density" to Household Data

2. Stragety
 (1) Merge: Use the common variable "department" Population Density Data with Household Data.
    (a) In Population Density Data
	   (i) Change column name (variable name) "NOM CIRCONSCRIPTION" to "department" (watch: NOM CIRCONSCRIPTION has a space in between)
	   (ii) Delete miscellaneous rows (ex. DISTRICT AUTONOME..., PREFACTURES) - only keep department values (ex. DEPARTEMENT D' ABIDJAN, DEPARTEMENT D' ATTIEGOUAKRO) under NOM CIRCONSCRIPTION column	   
	   (iii) Convert all "department" values into lowercase

     (b) In Household Data
	    (i) Convert variable name "b06_departemen" to "department"
     (c) Merge the 2 datasets using the common variable "department"
	 
 (2) Add "population_density" Column
     (a) In Population Density Data
	    (i) Change column name (variable name) "DENSITE AU KM²" into "population_density"
		(ii) Add "population_density" variable in Population Density Data to Household Data using "department" as the base for merging
*/

* Import Population Density Data
import excel "$wd\week_05\03_assignment\01_data\q2_CIV_populationdensity.xlsx", firstrow clear

* Rename key variables (NOMCIRCONSCRIPTION > department, DENSITEAUKM > population_density) in Population Density Data to prepare for mergeing
rename NOMCIRCONSCRIPTION department
rename DENSITEAUKM population_density

* Only Retain "department" level values
keep if regexm(department, "DEPARTEMENT")

* Delete miscellaneous text (ex. DEPARTEMENT D') in "department" values. Only retain "department" names. Why? To match values with the Household Data (Master Data)
replace department = regexs(1) if regexm(department, "DEPARTEMENT D'(.+)")
replace department = regexs(1) if regexm(department, "DEPARTEMENT DE (.+)")
replace department = regexs(1) if regexm(department, "DEPARTEMENT DU (.+)")

* Convert "deparment" values into lowercase to match with the Household Data (Master Data)
replace department = lower(trim(department))

* Save the New Population Density Data (Cleaned)
save "$wd\week_05\03_assignment\01_data\q2_CIV_populationdensity_cleaned.dta", replace

* Import Household Data
global q2_civ_section_0 "$wd\week_05\03_assignment\01_data\q2_CIV_Section_0.dta"
use "q2_CIV_Section_0", clear
decode b06_departemen, gen(department)
replace department = "arrah" if department == "arrha"

* Merge Household Data (Master Data) with Population Density Data (Using Data)
merge m:1 department using "$wd\week_05\03_assignment\01_data\q2_CIV_populationdensity_cleaned.dta", keepusing(population_density)

* Drop unmatched values in Using Data (Population Density Data)
drop if _merge == 2

* Drop _merge & department to only retain a single column for "population_density"
drop _merge department



****Q3****
/*
1. Objective
   Assign 19 enumerators to households that are clustered nearby to raise efficiency
   
2. Strategy
   (1) Use "latitude" and "longitude" variable to calculate which households that are close to one another can be combined into the same cluster (19 clusters) - K-Means Clustering
   (2) Assign 19 enumerators to each cluster
   (3) Distribute the 19 clusters evenly among households
*/

* Load Data
use "q3_GPS Data.dta", clear

* Ensure "latitude" and "longitude" are numeric variables
confirm numeric variable latitude longitude

* Use K-Means Clustering to assign households to enumerators
// Ensure Reproducibility
set seed 42

// K-Means Clustering
cluster kmeans latitude longitude, k(19) name(enumerator_cluster)

// Save Clustering Result
gen cluster = enumerator_cluster

// Before sorting, create observation number variable that indicates row number / row index - After sorting (assigning enumerator_ids based on clusters ex. enumerator_id 1: household 1-6), it may be hard to can track which household was assigned to which enuerator_id. This helps later identify which household (rrow index) was assigned to which enuerator_id
gen obs_number = _n

// Sort by cluster and observation number
sort cluster obs_number

* Assign / distribute enumerators evenly across clusters (create "enuerator_id")
// mod(): modulo function through 19 enumerators
// _n: row index after sorting by cluster
// mod(_n, 19) + 1: assigns enumerators in rotate (ex. row 1 > enumerator 1, row 2 > enumerator 2, ..., row 19 > enumerator 19, row 20 > enumerator 1 and repeat)
gen enumerator_id = mod(_n, 19) + 1

* Save the updated dataset
save "q3_GPS_Data_enumerator_assigned.dta", replace



****Q4****
/*
1. Objective
   Convert long format data to wide format data (1 row per ward & for each ward - multiple columns by party)
   
2. Strategy
   (1) Use reshape wide function
*/


* Load Data
import excel "q4_Tz_election_2010_raw.xls", sheet("Sheet1") cellrange(A5) firstrow clear

* Drop miscellaneous variables
drop SEX G ELECTEDCANDIDATE K

* Convert Variable Names into Lowercase
foreach var of varlist _all {
    local lowercasevar = lower("`var'")
    rename `var' `lowercasevar'
}

* Fix misspelled variable name
rename costituency constituency

* Foward Filling: region, district, costituency, ward
replace region = region[_n-1] if region == ""
replace district = district[_n-1] if district == ""
replace constituency = constituency[_n-1] if constituency == ""
replace ward = ward[_n-1] if ward == ""

* Drop Empty Value
drop if missing(region)

* Convert all string values to lowercase (*except political party)
foreach var in region district ward {
	replace `var' = lower(`var')
}

* Convert "ttlvotes" into numeric variable
replace ttlvotes = "" if ttlvotes == "UN OPPOSSED"
destring ttlvotes, replace

* Create "ward_id" variable
bysort region district constituency ward: gen ward_id = _n == 1  
replace ward_id = sum(ward_id)

* Create "ttlcandidates": assign the number of candidates per ward
bysort region district constituency ward (can): gen ttlcandidates = _N

* Create "ttlvotes": assign the number of total votes per ward
bysort ward_id: egen ward_ttlvotes = sum(ttlvotes)

* Create "num_votes" : assign number of total votes per party in each ward
bysort ward_id politicalparty (ward_id): egen num_votes = sum(ttlvotes)

* Drop miscellaneous variables
drop candidatename ttlvotes

* Drop duplicates: confirm if duplicates exist
duplicates drop

* Fix "politicalparty" values: delete spaces, convert dash to underscore
replace politicalparty = subinstr(politicalparty, " ", "", .)
replace politicalparty = subinstr(politicalparty, "-", "_", .)

* Pivot Long Format > Wide Format
reshape wide num_votes, i(region district constituency ward ttlcandidates ward_ttlvotes ward_id) j(politicalparty) string


****Q5****
/*
1. Objective
   Merge "ward" column in School Location Data (using data) into PSLE Data (master data)
   (*watch: some schools may not have matching ward info.)
   (*watch: PSLE Data has less number of observations than School Location Data)
   
2. Strategy
   (1) Exact Matching: Use common variables (region, district / council, school name)
   (*school name DOESN'T WORK - not exactly matching)
   (2) Fuzzy Matching: Use reclink function
*/

* PSLE Data (Master Data)
* School Location Data (Using Data)

* Load School Location Data
use "q5_school_location.dta", clear

* Retain Row Index (SN): for later tracking of Exact Matching - School Location Data (SN - originally string) & PSLE Data (serial - numeric)
destring SN, replace

* Rename variables into matching with PSLE Data (Master Data) & data friendly format: lowercase, underscore
rename Region region_name
rename Council district_name
rename Ward ward_name

* Convert lowercase values variables into uppercase values to match with PSLE Data (Master Data)
replace region_name = upper(region_name)
replace district_name = upper(district_name)

* Save the changes to Temporary File
tempfile q5_1
save `q5_1', replace emptyok

* Load PSLE Data (Master Data)
use "q5_psle_2020_data.dta", clear

* Create "School" Variable to match with School Location Data (Using Data) & Fix values to only retain school name
gen str School = regexs(1) if regexm(schoolname, "^(.*)\s*PRIMARY\s*SCHOOL")
replace School = regexs(1) if regexm(schoolname, "^(.*)\s*ACADEMY")
replace School = regexs(1) if regexm(schoolname, "^(.*)\s*PRE")
replace School = regexs(1) if regexm(schoolname, "^(.*)\s*ENGLISH")
replace School = regexs(1) if regexm(schoolname, "^(.*)\s*-\s*PS") & missing(School)
replace School = subinstr(School, " PRIMARY SCHOOL", "", .)
replace School = subinstr(School, " PRIMARY", "", .)
replace School = subinstr(School, " ELEMENTARY", "", .)
replace School = trim(School)

* Install reclink for Fuzzy Matching
ssc install reclink

* Fuzzy Matching
reclink region_name School using `q5_1', idmaster(serial) idusing(SN) gen(score) 
keep region_name district_name ward_name schoolname school_code_address region_code district_code serial
sort serial


****Bonus Q****
/*
1. Objective
   Match 2015 wards with their 2010 parents wards
2. Strategy
   Use gis-based intersection data
*/

* Load Data
use "Tz_GIS_2015_2010_intersection.dta", clear

* Rename 
rename (region_gis_2017 district_gis_2017 ward_gis_2017) (region_15 district_15 ward_15)

* Create a Temporary File (prepare for merging)
tempfile intersection
save `intersection', replace emptyok

* Load Data
use "Tz_elec_15_clean.dta", clear

* Merge: intersection Data with 2015 Data
reclink region_15 ward_15 using `intersection', idm(ward_id_15) idu(fid_gis_2017) gen(score)

* Check duplicates
duplicates drop ward_id_15, force

* Retain only relevant variables
keep ward_id_15 region_15 district_15 ward_15 region_gis_2012 district_gis_2012 ward_gis_2012