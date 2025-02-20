********************************************************************************
* Econ 4490: Week 2 
* Exploring and manipulating data in Stata
* Ali Hamza
* Sep 10th, 2024
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
  
  
  
/* 
"All happy families are alike; each unhappy family is unhappy in its own way."

- Tolstoy
*/




/*******************************************************************************
1. Introduction to Stata:
*******************************************************************************/
/*

COMMAND: You can tell Stata what to do by typing in commands. Click inside the 
		 command window and type  

RESULTS: Here Stata displays the commands followed by the output that Stata has 
		 produced. 

VARIABLES: Lists all the variables in the dataset. The variable window can act 
		   as a shortcut for creating commands. Try clicking on one of the 
		   variables. It should appear in the command window, eliminating the 
		   need for you to write it out.

REVIEW: Lists all your prior commands. You can copy/paste commands from here

DATA BROWSWER: view your data, including variable names, labels, and their 
			   values


******STATA FILES*******

* datasets: .dta 
* do files: .do
* log files: .smcl / .log

*/ 


/*******************************************************************************
2. STATA Directories:
*******************************************************************************/

/* 
pwd 
This commands let's you know your current working directory:
*/

pwd

/* 
cd 
You can use this command to change working directory.
*/

*Example 

cd "/Users/ah1152/Desktop/ppol6618/week_03/02_data"

*IMP: change the working directory before running this

* Note: If your directory_name contains embedded spaces, remember to enclose 
*       it in double quotes.

/* 
dir
display filenames and folders in current working directory
*/

/*
cd ..
will move you up one directory
*/


/*******************************************************************************
3. LOADIND DATASETS:
*******************************************************************************/

*clear
*This command removes data and value labels from memory


*use
* This command is used to load .dta files

*We can also use Stata datasets using sysuse command
use student_char.dta, clear
 
********************************************************************************
*4. Saving datasets 
********************************************************************************

*save & replace
* to save a new dataset


*export
*same as import function


*export excel using excel1_new.xls, replace firstrow(var) //if you want first row in excel to be the variable names
*export excel using excel1_new.xls, replace firstrow(varlab) //if you want first row in excel to be the variable labels 

*in this case it will be the same because variable names = variable labels

*You can also export only certain variables
*export excel make price mpg rep78 using excel1_new.xls, replace 




********************************************************************************
*5. Exploring Data 
********************************************************************************
/*
desribe
Itproduces a summary of the dataset in memory or of the data stored in a 
Stata-format dataset.
*/

describe


/*
codebook
It examines the variable names, labels, and data to produce a codebook 
describing the dataset. If no varlist is specified, summary statistics are 
calculated for all the variables in the dataset.
*/

codebook
codebook attendance

/*
summarize: 
It calculates and displays a variety of univariate summary statistics.  If no 
varlist is specified, summary statistics are calculated for all the variables in 
the dataset.
*/

summarize
summarize math
summarize math, d
summarize name

* Only numeric variables

/*
list:
It displays the values of variables.  If no varlist is specified, the values 
 of all the variables are displayed.
*/

list id name student school female math reading in 1/10



/*
tabulate (one-way)
It produces a one-way table of frequency counts.
*/

tab school

/*
tabulate (two way)
it produces a two-way table of frequency counts, along with various measures of 
association, including the common Pearson's chi-squared, the likelihood-ratio 
chi-squared, Cramér's V, Fisher's exact test, Goodman and Kruskal's gamma, 
and Kendall's tau-b.
*/

tab  attendance female
tab  attendance female, row
tab  attendance female, column

/*
count
It counts the number of observations that satisfy the specified conditions.  
If no conditions are specified, count displays the number of observations in 
the data.
*/

count  
count if attendance>.8279487

/*
display
displays strings and values of scalar expressions.  display produces output 
from the programs that you write.

It's not just a calculator!
*/



/*******************************************************************************
*6. GENERATING NEW VARIABLES AND DATA CLEANING 
*******************************************************************************/

/*
generate:
creates a new variable.  The values of the variable are specified by =exp.
*/

gen total1=.
gen total2=""

/*
drop
drop eliminates variables or observations from the data in memory.
*/

drop total1 total2 

/*
keep
oppositie of drop command.
*/

*
sysuse pop2000, clear
*

/*
recode
It changes the values of numeric variables according to the rules specified.
Values that do not meet any of the conditions of the rules are left unchanged, 
unless an otherwise rule is specified.
*/

recode agegrp (1=2)

/*
replace
It changes the contents of existing variable
*/

replace agegrp=4 if agegrp<4



/*******************************************************************************
*6. IMPOSING CONDITIONS
*******************************************************************************/
sysuse auto2, clear

*IF
* if at the end of a command means the command is to use only the data specified.

summarize price if foreign ==0
summarize price if foreign ==1

*AND condition (&)
summ price if foreign ==0 & rep78==3


*OR condition (|)
summ price if foreign ==0 | rep78==3



/*******************************************************************************
*7. ANNOTATION
*******************************************************************************/

/*
Hello, World!
*/


* Hello, World

// Hello, World

********************************************************************************
*8. Labels & Value labels 
********************************************************************************

use student_char.dta, clear

** a. Labels 
/*In the browse window, you can see on the right the variable names, 
and a label for each variable (variable label). */

*The labels are assigned to the variables using the following command: 
label variable id "" //to label variable called id 
*You can change a variable's label as many times as you want, it's automatically replaced 
label variable id "Unique Dtudent ID"

** b. Value labels
/*Some variables are numeric such as income.
Other variables are numeric, but they really refer to categories (categorical variables)
Examples include: variable called female, defined as 1=female and 0=male. 
We assigned value labels to categorical variables to make analysis easier and avoid typos. 
This is done by first defining the value label, then assigning it to a variable. */

label define gender 1 "Female" 0 "Male" //gender is the name of the value label
label values female "gender" //here the variable is called female. 

labelbook



*********************************************************************************/
*9. Wildcards in variable names:
*********************************************************************************/
/*Stata has characters called wildcards, these are mainly "*" and "?" 
These allow you to quickly call for variables that share a common part of their names.
For example, if you want to browse variables of household number, village, and region.
And you know that all of these end with the suffix _id (for example: hh_id village_id region_id)
You can then use:*/

/*The * mean ANYTHING. So any variable that ends with _id will be browsed

The difference between * and ? is that * has no limit on the number of characters.
for example, hhid_id has 4 characters before _id (h h i d)
 whie village_id has 7 characters. The asterix * covers them both. 

However, if you only want variables that have a specific number of characters before _id, you can use the ? wildcards.
? means that the character can be anything, but it represents one and only one character */ 

codebook ???e
codebook *e


********************************************************************************
*10. Variables & observations order:
********************************************************************************
*When browsing your data, you can see that variables always appear in the same order
*Some examples: 
order name
order school id name
order name, last 

*This new order will be preserved as long as you're working with the dataset, and if you save the new dataset 
*This is a permanent change that you make (you can re-order, of course) 


*You can also sort your observations in different order. 
*Observations are usually sorted so that all observations belonging to the same region, village, household, for example,
*appear right after each other. 
*If that's not the case in your dataset, you can fix that by the sort command. ex:
sort school id  
*Your dataset would look like this:
/*
region_id		village_id 		hhid 	 
1					1			 1	
1					1			 2
1					2			 1
1					2			 2

Sort always sorts in ascending order. Sometimes you might want to sort in descending order 
In that case you use gsort and add a minus sign in front of the variable, ex:*/
gsort -attendance


gsort -attendance -reading -math 

//run it mulitple times and see what happens to first 5 obs
















