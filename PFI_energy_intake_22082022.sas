/*-------------------------------*/
/* IMPORT DATA FROM EXCEL FILE   */
/*-------------------------------*/

%web_drop_table(energy_intake);


FILENAME REFFILE '/home/u50127452/sasuser.v94/PolyFoodIntake/SAS_PolyFoodIntake_05_10_2021.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=energy_intake;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=energy_intake; RUN;


%web_open_table(energy_intake);

/*---------------------------------------------------*/
/* CHECK DISTRIBUTION TEST MEAL ONLY				*/
/*---------------------------------------------------*/
proc univariate data=energy_intake;
var energy_testmeal_wo_preload_kcal;
histogram energy_testmeal_wo_preload_kcal / normal; 
run;
/*Kolmogorov p-value<0.010 --> not normally distributed*/

proc univariate data=energy_intake;
var energy_testmeal_wo_preload_kcal;
histogram energy_testmeal_wo_preload_kcal / normal (mu=est sigma=est) lognormal (sigma=est theta=est zeta=est); 
run;
/*Kolmogorov p-value<0.010--> not normally distributed*/

/* box-cox transformation */
data energy_intake;
set energy_intake;
z=0;
run;
/* adds variable z with all zeros, needed in proc transreg */

proc transreg data=energy_intake maxiter=0 nozeroconstant;
   	model BoxCox(energy_testmeal_wo_preload_kcal/parameter=0) = identity(z);
run;
/* check lambda in output, in this case 0, no negative parameters
parameter is constant to make all values positive if there are negative values, hence parameter = |minimum|, see below */

data energy_intake;
set energy_intake;
bc_ei_wo_preload_kcal = log(energy_testmeal_wo_preload_kcal);
run;
/* boxcox formula, 0 is lambda, or formula: Y^0.5 = √(Y) ??*/

/* check normality of box-cox transformed variable */
proc univariate data=energy_intake;
var bc_ei_wo_preload_kcal;
histogram bc_ei_wo_preload_kcal / normal (mu=est sigma=est);
run;

/*--------------------------------------------------------------------------*/
/* CHECK DISTRIBUTION TOTAL ENERGY INTAKE (TEST MEAL AND PRELOAD)			*/
/*--------------------------------------------------------------------------*/
proc univariate data=energy_intake;
var total_energy_intake_kcal;
histogram total_energy_intake_kcal / normal (mu=est sigma=est) lognormal (sigma=est theta=est zeta=est);
run;
/* */

/* box-cox transformation */
data energy_intake;
set energy_intake;
z=0;
run;
/* adds variable z with all zeros, needed in proc transreg */

proc transreg data=energy_intake maxiter=0 nozeroconstant;
   	model BoxCox(total_energy_intake_kcal/parameter=0) = identity(z);
run;
/* check lambda in output, in this case 0
parameter is constant to make all values positive if there are negative values, hence parameter = |minimum|, see below */

data energy_intake;
set energy_intake;
bc_total_ei_kcal = log(total_energy_intake_kcal);
run;
/* boxcox formula, 0 is lambda --> use log(variable)*/

/* check normality of box-cox transformed variable */
proc univariate data=energy_intake;
var bc_total_ei_kcal;
histogram bc_total_ei_kcal / normal (mu=est sigma=est);
run;


proc univariate data=energy_intake;
var total_energy_intake_kcal;
histogram total_energy_intake_kcal / normal (mu=est sigma=est) lognormal (sigma=est theta=est zeta=est);
run;


/*-------------------------------*/
/* energy intake testmeal only   */
/*-------------------------------*/

/*adjusted for normality*/ 
proc mixed data=energy_intake;
class subject condition;
model bc_ei_wo_preload_kcal = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;

/*NOT adjusted for normality*/
proc mixed data=energy_intake;
where energy_testmeal_wo_preload_kcal < 1200;
class subject condition;
model energy_testmeal_wo_preload_kcal = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;

/* "wo" means without */

/*--------------------------------------------*/
/* Total energy intake (pre-load+testmeal)   */
/*-------------------------------------------*/

/*adjusted for normality*/
proc mixed data=energy_intake;
class subject condition;
model bc_total_ei_kcal = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;

/*NOT adjusted for normality*/
proc mixed data=energy_intake;
class subject condition;
model total_energy_intake_kcal = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;