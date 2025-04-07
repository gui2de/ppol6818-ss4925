/*
Class: PPOL_6818
Student: Su Yeon Seo
Net ID: ss4925
Deliverable: Stata 4
*/


* Set Working Directory
if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818\week_10\03_assignment"
}

if c(username)=="suyeo" { //this would be your username on your computer
	
	global wd "C:\Users\suyeo\Desktop\ppol_6818\week_10\03_assignment" //this would your ppol_6818 folder address
}

cd "$wd"

****Part 1: Power calculations for individual-level randomization****
*1. Develop a data generating process for some Y that is normally disturbed around 0 with standard deviation of 1.

clear all 
set more off
set obs 12000 // 12,000 observations
set seed 1234 // seed for reproducibility
gen outcome = rnormal(0,1) // simulate normally distributed outcome variable (mean =0, sd = 1)

*2.The average treatment effect should be 0.1 sd (with the effects being uniformly distributed between 0.0 – 0.2 sd)

gen effect = runiform(0,0.2) // assign individual treatmen effects from a uniform distribution [0.05, 0.25]

*3. The proportion of individuals receiving treatment should be 0.5 (i.e. half in control, and half in treatment) Calculate the number of individuals required to reach 80% power when you are trying to detect 0.1 sd treatment effect.

// randomly assign 50% of sample to treatmen group
gen shuffle = runiform()
sort shuffle
gen group = 0
replace group = 1 in 1/6000   // 50% of 12,000 observations
drop shuffle

*4. Now assume, 15% of the sample will attrite (assume similar attrition rates in control and treatment arms.) How does this change your sample size calculations from the previous part?

// Power calculation to detect a 0.15 SD difference with 80% power
power twomeans 0 0.15, sd(1) power(0.8)

// Adjust sample size for 20% attrition (new assumption)
// New required sample size = baseline sample size / (1 - 0.2)
// If base is 1402, then needed sample = 1402 / 0.8 ≈ 1753
display 1402 / 0.8

*5.	Now assume the intervention is very expensive and we can only afford to provide this specific treatment to 30% of the sample. How would this change the sample size needed for 80% power.
// Assume only 30% of individuals can be treated (e.g., costly intervention)
// Treatment: 30%, Control: 70% → nratio = 0.7/0.3 ≈ 2.33
power twomeans 0 0.15, sd(1) power(0.8) nratio(0.7/0.3)


****Part 2: Power calculations for cluster randomization****
/*1.	Develop data generating process for data for Y (assume math score of each individual student) in a school. We can only assign treatment at the school-level.
2.	Your function should be able to change the number of clusters (i.e. schools) and the cluster size (i.e. number of students in each school)
3.	Make sure the rho/icc is ~ 0.3 when generating these clusters. Hint.
4.	Divide the schools evenly between treatment and control arms. And generate a treatment effect of 0.2 sd (with the effects being uniformly distributed between 0.15 – 0.25 sd)
*/

// Simulation program with flexible number of schools and students
clear all
set more off
set seed 1234   // Different random seed for reproducibility

capture program drop sim_school
program define sim_school, rclass
    syntax, numschools(integer) classsize(integer)

    clear
    local total = `numschools' * `classsize'
    set obs `total'

    * Assign school ID to each student
    gen school_id = floor((_n - 1) / `classsize') + 1

    * Randomize school-level treatment
    preserve
    keep school_id
    duplicates drop
    gen school_rand = runiform()
    tempfile school_random
    save `school_random'
    restore

    merge m:1 school_id using `school_random', nogen

    gen assign = 0
    quietly {
        count
        local N = r(N)
        replace assign = 1 in 1/`=`N'/2'
    }

    * Set ICC = 0.3: 30% of variance from school-level random effect
    scalar var_school = sqrt(0.3)
    scalar var_student = sqrt(0.7)

    * Generate school-level random effects
    gen rand_eff = .
    quietly forvalues s = 1/`numschools' {
        local school_val = rnormal(0, var_school)
        replace rand_eff = `school_val' if school_id == `s'
    }

    * Individual-level residuals
    gen resid = rnormal(0, var_student)

    * Generate individual-specific treatment effects
    gen treat_effect = runiform(0.15, 0.25)

    * Final outcome: math score
    gen math_score = 50 + 0.2 * assign + rand_eff + resid

    * Estimate treatment effect
    reg math_score assign

    return scalar p = 2 * (1 - normal(abs(_b[assign] / _se[assign])))
end

*5.	Holding the number of clusters fixed at 200, what happens to the power when you increase the cluster size (use first 10 powers of 2) What cluster size would you recommend and why?

// Power simulation: Fix number of schools at 200, vary class size (2^0 to 2^9)
clear
tempfile school_power
save `school_power', replace emptyok

local sizes
forvalues i = 0/9 {
    local val = 2^`i'
    local sizes `sizes' `val'
}

foreach n of local sizes {
    display "Running simulation for class size = `n'..."
    clear

    simulate p = r(p), reps(100): sim_school, numschools(200) classsize(`n')

    sum p
    local avg_p = r(mean)

    clear
    set obs 1
    gen class_size = `n'
    gen avg_pval = `avg_p'

    append using `school_power'
    save `school_power', replace
}

/*
Recommendation: Cluster size - 32 students per school

Explanation: 
(1) Power Increases with Cluster Size — But Only Up to a Point
- As you increase the number of students per cluster (e.g., from 1 → 2 → 4 → 8 → 16...), the statistical power improves, because you're getting more data to estimate treatment effects.
- However, in cluster-randomized trials, the number of clusters (schools) matters more than the number of individuals per cluster — especially when intraclass correlation (ICC) is high.

(2) High ICC (0.3) Means Redundancy Within Clusters
- An ICC of 0.3 implies that students in the same school are quite similar.
- So, after a certain point, adding more students per school gives you little new information, since responses are correlated.

(3) Simulation Results Support 32 as a Sweet Spot
Based on my simulation results...
- Power increases rapidly as cluster size grows up to ~32.
- After that, gains in power are minimal or even inconsistent.
- In some cases, p-values increase beyond 32 students due to variance instability.

(4) Tradeoff Between Power and Cost
Cluster size = 32 balances...
- Strong statistical power
- Reasonable total sample size
- Avoids diminishing returns

Conclusion:
As a result, I recommend a cluster size of 32 students per school.
It offers strong power without unnecessary cost or redundancy, especially under high ICC (0.3). Going beyond 32 adds little value due to correlated outcomes within clusters.
*/

*6.	Now hold the cluster size fixed (15 students/school). 
// Fixed class size = 15 students per school
power twomeans 0 0.2, cluster m1(15) m2(15) rho(0.3) power(0.8)

* How many schools do you need in your RCT to get 80% to detect 0.2 sd treatment effect?
// 274 schools (137 treatment + 137 control)

*7.	Now assume that only 70% of the schools actually adopt your treatment.
// Only 70% of treatment schools comply
// Effective treatment effect = 0.2 * 0.7 = 0.14
power twomeans 0 0.14, cluster m1(15) m2(15) rho(0.3) power(0.8)

* How many schools do you need now to get 80% power?
// 556 schools required to maintain 80% power


****Part 3: De-biasing a parameter estimate using controls****
/*1.	Develop some data generating process for outcome Y, with some treatment variable and treatment effect. 
2.	This DGP should include strata groups and continuous covariates, as well as random noise. Make sure that the strata groups affect the outcome Y. You will want to create the strata groups first, then use a command like expand or merge to add them to an individual-level data set.
3.	Make sure that at least one of the continuous covariates also affects both the outcome and the likelihood of receiving treatment (a "confounder"). Make sure that another one of the covariates affects the outcome but not the treatment. Make sure that another one affects the treatment but not the outcome. (What do these do?)
*/

// Data Generating Process
clear all
set obs 10000 

// Create strata (grouping) variable
gen group_id = ceil(runiform() * 5)

// Generate covariates
gen confounder = rnormal()   // Affects both treatment and outcome
gen yvary = rnormal()        // Affects outcome only
gen tvary = rnormal()        // Affects treatment only

// Treatment assignment depends on confounder and tvary
gen p_treat = 0.4 * confounder + 0.7 * tvary
gen treat = (runiform() < p_treat)

// Random error term
gen noise = rnormal(0, 1)

// Outcome: true treatment effect = 0.5
gen outcome = 0.5 * treat + 0.8 * confounder + 0.3 * yvary + group_id + noise

save "debiased_data.dta", replace


*4.	Construct at least five different regression models with combinations of these covariates and strata fixed effects. (Type h fvvarlist for information on using fixed effects in regression.) Run these regressions at different sample sizes, using a program like last week. Collect as many regression runs as you think you need for each, and produce figures and tables comparing the biasedness and convergence of the models as N grows. Can you produce a figure showing the mean and variance of beta for different regression models, as a function of N? Can you visually compare these to the "true" parameter value?

// Program to run 5 regression models and return treatment coefficients
capture program drop run_models
program define run_models, rclass
    syntax, n(integer)

    use "debiased_data.dta", clear
    sample `n', count

    // Model 1: Only treatment
    reg outcome treat
    return scalar b1 = _b[treat]
    return scalar ci_low1 = _b[treat] - 1.96 * _se[treat]
    return scalar ci_high1 = _b[treat] + 1.96 * _se[treat]

    // Model 2: Add confounder
    reg outcome treat confounder
    return scalar b2 = _b[treat]
    return scalar ci_low2 = _b[treat] - 1.96 * _se[treat]
    return scalar ci_high2 = _b[treat] + 1.96 * _se[treat]

    // Model 3: Add confounder + yvary (affects Y only)
    reg outcome treat confounder yvary
    return scalar b3 = _b[treat]
    return scalar ci_low3 = _b[treat] - 1.96 * _se[treat]
    return scalar ci_high3 = _b[treat] + 1.96 * _se[treat]

    // Model 4: Add strata fixed effects
    xtset group_id
    xtreg outcome treat confounder yvary, fe
    return scalar b4 = _b[treat]
    return scalar ci_low4 = _b[treat] - 1.96 * _se[treat]
    return scalar ci_high4 = _b[treat] + 1.96 * _se[treat]

    // Model 5: Add everything including tvary (affects treatment only)
    xtreg outcome treat confounder yvary tvary, fe
    return scalar b5 = _b[treat]
    return scalar ci_low5 = _b[treat] - 1.96 * _se[treat]
    return scalar ci_high5 = _b[treat] + 1.96 * _se[treat]
end

clear
tempfile regression_results
save `regression_results', replace emptyok

local sizes 100 250 500 1000 5000 10000

foreach N of local sizes {
    display "Running simulations for N = `N'..."

    simulate ///
        b1 = r(b1) ci_low1 = r(ci_low1) ci_high1 = r(ci_high1) ///
        b2 = r(b2) ci_low2 = r(ci_low2) ci_high2 = r(ci_high2) ///
        b3 = r(b3) ci_low3 = r(ci_low3) ci_high3 = r(ci_high3) ///
        b4 = r(b4) ci_low4 = r(ci_low4) ci_high4 = r(ci_high4) ///
        b5 = r(b5) ci_low5 = r(ci_low5) ci_high5 = r(ci_high5), ///
        reps(100): run_models, n(`N')

    gen N = `N'
    append using `regression_results'
    save `regression_results', replace
}

// Summarize Results & Plot
use `regression_results', clear

collapse (mean) b* ci_*, by(N)

reshape long b ci_low ci_high, i(N) j(model)
sort N model

// Table: Coefficient by N
// View convergence of beta estimates
table N, statistic(mean b ci_high ci_low) nformat(%9.6f)

// Plot 1: Coefficient convergence over sample size
preserve
collapse (mean) b ci_high ci_low, by(N)
gen str_N = string(N)
gen Ni = _n

ssc install labutil, replace
labmask Ni, values(str_N)

#delimit ;
twoway 
    (rcap ci_low ci_high Ni, lcolor(gs10)) 
    (scatter b Ni, mcolor(black)),
    xlabel(1(1)6, valuelabel)
    xtitle("Sample Size N")
    legend(order(1 2) pos(1) ///
           label(1 "Confidence Interval") ///
           label(2 "Coefficient Estimate") size(small))
;
#delimit cr

graph export "coeff_convergence.jpg", replace
restore

// Table: Coefficient by model
table model, statistic(mean b ci_high ci_low) nformat(%9.6f)

// Plot 2: Bias and variance by model
preserve
collapse (mean) b ci_high ci_low, by(model)

label define model_lbl 1 "Treat only" ///
                      2 "Treat + Confounder" ///
                      3 "Add Y-only Var" ///
                      4 "Add FE" ///
                      5 "All Covariates"

label values model model_lbl

#delimit ;
twoway 
    (rcap ci_low ci_high model, lcolor(gs10)) 
    (scatter b model, mcolor(black)),
    xlabel(1(1)5, valuelabel angle(0))
    xtitle("Model")
    legend(order(1 2) pos(1) ///
           label(1 "Confidence Interval") ///
           label(2 "Coefficient Estimate") size(small))
;
#delimit cr

graph export "model_bias_variance.jpg", replace
restore


*5.	Fully describe your results in your README file, including figures and tables as appropriate.
