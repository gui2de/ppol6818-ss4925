/*
Class: PPOL_6818
Student: Su Yeon Seo
Net ID: ss4925
Deliverable: Stata 3
*/


* Set Working Directory
if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="suyeo" { //this would be your username on your computer
	
	global wd "C:\Users\suyeo\Desktop\ppol_6818" //this would your ppol_6818 folder address
}

cd "$wd"


* Part 1. Fixed Population Creation
/*1. Develop Data Generating Process (DGP)
// Define a simple linear relationship between X (predictor) & Y (outcome)
Y = 2 + 3X + ε
where X ~ N(0,1), ε ~ N(0,1)

The true regression coefficient (beta) for X is 3.0, and will generate N = 10,000 individuals as a fixed population.
*/


*2. Create Fixed Population Data
clear all
set seed 12345 // always create the same data set of the same random values
set obs 10000 // number of observations 10,000

gen X = rnormal(0,1) // generate X : random draw from a standard normal distribution (mean = 0, SD = 1)
gen e = rnormal(0,1) // generate error term : random draw from a standard normal distribution (mean = 0, SD = 1)
gen Y = 2 + 3*X + e // generate Y: calculate using DGP above

save "fixed_population.dta", replace


*3. Define Program 
capture program drop regsim // deletes any pre-existing "regsim", avoid conflicts
program define regsim, rclass // program - define new "regsim"
    args n // argument - sample size (n) 

    use "fixed_population.dta", clear // (a) loads this data

    sample `n', count // (b) randomly samples a subset whose sample size is an argument to the program

    regress Y X // (c) performs regression of Y on X
	
	test X
    return scalar N = e(N) // (d) returns N (sample size)
    return scalar beta = _b[X] // returns beta (estimated coefficient)
    return scalar sem = _se[X] // returns SEM (standard error of the mean) - standard error of the estimated regression coefficient (beta)
    return scalar p = r(p) // returns p-value
    return scalar ci_low = _b[X] - invttail(e(df_r), 0.025)*_se[X] // returns confidence interval (lower bound)
    return scalar ci_high = _b[X] + invttail(e(df_r), 0.025)*_se[X] // returns confidence interval (upper bound)
end


*4. Simulation
simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) ci_low=r(ci_low) ci_high=r(ci_high), /// 
    reps(500) seed(12345): regsim 10 // run program 500 times, sample size = 10
save "sim_results_n10.dta", replace

simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) ci_low=r(ci_low) ci_high=r(ci_high), /// 
    reps(500) seed(12345): regsim 100 // run program 500 times, sample size = 100
save "sim_results_n100.dta", replace

simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) ci_low=r(ci_low) ci_high=r(ci_high), /// 
    reps(500) seed(12345): regsim 1000 // run program 500 times, sample size = 1,000
save "sim_results_n1000.dta", replace

simulate N=r(N) beta=r(beta) sem=r(sem) p=r(p) ci_low=r(ci_low) ci_high=r(ci_high), /// 
    reps(500) seed(12345): regsim 10000 // run program 500 times, sample size = 10,000
save "sim_results_n10000.dta", replace

// Combine files
use sim_results_n10.dta, clear
gen N_group = 10
append using sim_results_n100.dta
replace N_group = 100 if missing(N_group)
append using sim_results_n1000.dta
replace N_group = 1000 if missing(N_group)
append using sim_results_n10000.dta
replace N_group = 10000 if missing(N_group)

save "combined_sim_results.dta", replace


*5. Create Table & Figures showing variation of coefficient (beta estimates) depending on sample size 
// Table. Summary Statistics
table N_group, statistic(mean beta) statistic(sd beta) statistic(mean sem)

// Figure 1. Histogram of Betas by Sample Size
graph box beta, over(N_group) title("Distribution of Beta Estimates by Sample Size")

graph export "stata_3_part_1_figure_1.png"

// Figure 2. Line Graphs of Standard Errors and Confidence Intervals
collapse (mean) sem ci_low ci_high, by(N_group) // reduce dataset to one row per sample size - replace current dataset with mean values of (sem, ci_low, ci_high)

twoway (line sem N_group, sort lpattern(solid)) ///
       (line ci_low N_group, sort lpattern(dash)) ///
       (line ci_high N_group, sort lpattern(dash)), ///
       title("SEM and Confidence Intervals vs. Sample Size") ///
       legend(order(1 "SEM" 2 "CI Low" 3 "CI High"))
	   
graph export "stata_3_part_1_figure_2.png"


* Part 2. Sampling noise in an infinite superpopulation
*1. Define Program
capture program drop superpop_regsim // deletes any pre-existing "superpop_regsim", avoid conflicts
program define superpop_regsim, rclass // (a) randomly creates a data set whos sample size is an argument to the program following DGP in Part 1 - define superpop_regsim
    args n

    clear
    set obs n'
    set seed 1234

    // Generate new X and error each time
    gen X = rnormal(0,1) // generate X : random draw from a standard normal distribution (mean = 0, SD = 1)
    gen e = rnormal(0,1) // generate error term : random draw from a standard normal distribution (mean = 0, SD = 1)
    gen Y = 2 + 3*X + e // generate Y: calculate using DGP in Part 1

    regress Y X // (b) performs regression of Y on X

    test X
    return scalar N = e(N) // (c) returns N (sample size)
    return scalar beta = _b[X] // returns beta (estimated coefficient)
    return scalar sem = _se[X] // returns SEM (standard error of the mean) - standard error of the estimated regression coefficient (beta)
    return scalar p = r(p) // returns p-value
    return scalar ci_low = _b[X] - invttail(e(df_r), 0.025)*_se[X] // returns confidence interval (lower bound)
    return scalar ci_high = _b[X] + invttail(e(df_r), 0.025)*_se[X] // returns confidence interval (upper bound)
end

*2. Simulation
* Generate first 20 powers of 2: 2^2 to 2^21 (i.e., 4 to 2,097,152)
local powers2
forvalues i = 2/20 {
    local powers2 `powers2' `=2^`i''
}

* Generate first 6 powers of 10: 10^1 to 10^6 (i.e., 10 to 1,000,000)
local powers10
forvalues j = 1/6 {
    local powers10 `powers10' `=10^`j''
}

* Create a tempname and start postfile to collect results in memory
tempname simresults
tempfile final

postfile `simresults' N beta sem p ci_low ci_high N_group using `final', replace

* Run simulations (1) first 20 powers of 2, (2) first 6 powers of 10
foreach n in `powers2' `powers10' {
    display "Running simulation for N = `n'"
    
    forvalues rep = 1/500 {
        quietly {
            clear
            set obs `n'

            gen X = rnormal(0,1)
            gen e = rnormal(0,1)
            gen Y = 2 + 3*X + e

            regress Y X
            test X

            post `simresults' ///
                (e(N)) ///
                (_b[X]) ///
                (_se[X]) ///
                (r(p)) ///
                (_b[X] - invttail(e(df_r), 0.025)*_se[X]) ///
                (_b[X] + invttail(e(df_r), 0.025)*_se[X]) ///
                (`n')
        }
    }
}

* Close postfile and use the results
postclose `simresults'
use `final', clear


*3. Create Table & Figures showing the variation in coefficient (beta estimates) depending on sample size
// Table. Summary Statistics (*as N: sample size gets larger)
table N_group, statistic(mean beta) statistic(sd beta) statistic(mean sem)

// Figure. Line Graphs of Standard Errors and Confidence Intervals
collapse (mean) sem ci_low ci_high, by(N_group) // reduce dataset to one row per sample size - replace current dataset with mean values of (sem, ci_low, ci_high)

twoway (line sem N_group, sort lpattern(solid)) ///
       (line ci_low N_group, sort lpattern(dash)) ///
       (line ci_high N_group, sort lpattern(dash)), ///
       title("Part 2: SEM and Confidence Intervals vs. Sample Size") ///
       legend(order(1 "SEM" 2 "CI Low" 3 "CI High")) ///
       xscale(log) // helps handle large difference in sample size
	   
graph export "stata_3_part_2_figure_1.png"