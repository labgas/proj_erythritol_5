*IMPORT DATA FROM EXCEL FILE;
%web_drop_table(PFI_insulin);


FILENAME REFFILE '/home/u50127452/sasuser.v94/PolyFoodIntake/SAS_PolyFoodIntake_05_10_2021.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=PFI_insulin;
	GETNAMES=YES;
	SHEET="Hormones_glucose_appetite";
RUN;

PROC CONTENTS DATA=PFI_insulin; RUN;


%web_open_table(PFI_insulin);


*CHECK DISTRIBUTIONS;
proc univariate data=PFI_insulin;
var delta_insulin;
where time > -15;
histogram delta_insulin / normal(mu=est sigma=est) lognormal (sigma=est theta=est zeta=est);
run;
*transformation Kolmogorov-Smirnov p<0.010;

/* box-cox transformation */
data PFI_insulin;
set PFI_insulin;
z=0;
run;
/* adds variable z with all zeros, needed in proc transreg */

proc transreg data=PFI_insulin maxiter=0 nozeroconstant;
   	model BoxCox(delta_insulin/parameter=33) = identity(z);
run;
/* check lambda in output, in this case 0.25
parameter is constant to make all values positive if there are negative values, hence parameter = |minimum|, see below */

data PFI_insulin;
set PFI_insulin;
bc_delta_insulin = ((delta_insulin+33)**0.25 -1)/0.25;
run;
/* boxcox formula, 0.25 is lambda*/

/* check normality of box-cox transformed variable */
proc univariate data=PFI_insulin;
var bc_delta_insulin;
histogram bc_delta_insulin / normal (mu=est sigma=est);
run;
/*two outliers left*/

*MIXED MODEL ADJUSTED FOR NORMALITY;
proc mixed data=PFI_insulin;
where time > -15;
class subject condition time;
model bc_delta_insulin = condition | time total_energy_kcal / ddfm=kr2 solution influence residual;
repeated condition time / subject=subject type=un@ar(1) r rcorr;
lsmeans condition / diff=all;
lsmeans condition*time / slice=time;
lsmestimate condition*time
	'hypothesis 1: no increase from -16 baseline in erythritol at time -1 i.e. after preload before test meal' 1 0 0 0 0 0 0 0,
    'hypothesis 1: no increase from -16 baseline in sucralose at time -1 i.e. after preload before test meal' 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0,
    'hypothesis 1: increase from -16 baseline in sucrose at time -1 i.e. after preload before test meal' 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0,
	'hypothesis 1: no increase from -16 baseline in tap water at time -1 i.e. after preload before test meal' 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0/ adjdfe=row divisor = 1; 
	/*hypothesis 1: change or no change from -16 baseline (-16=0) after preload before test meal*/
lsmestimate condition*time
	'hypothesis 1: similar (=no) change from -16 baseline in erythritol compared to sucralose at time -1 i.e. after preload before test meal' 1 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0,
	'hypothesis 1: no increase from -16 baseline in erythritol compared to sucrose at time -1 i.e. after preload before test meal' 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0,
	'hypothesis 1: similar (=no) change from -16 baseline in erythritol compared to tap water at time -1 i.e. after preload before test meal' 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 / adjdfe=row adjust=bon stepdown joint (label='hypotheses 1');
	/*hypothesis 1: difference or no difference between test solutions after preload before test meal.*/ 
lsmestimate condition*time
	'hypothesis 2: change from baseline in erythritol at time 15 i.e. after preload and test meal' 0 1 0 0 0 0 0 0,
    'hypothesis 2: change from baseline in sucralose at time 15 i.e. after preload and test meal' 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0,
    'hypothesis 2: change from baseline in sucrose at time 15 i.e. after preload and test meal' 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0,
	'hypothesis 2: change from baseline in tap water at time 15 i.e. after preload and test meal' 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0/ adjdfe=row divisor = 7; 
	/*hypothesis 2: change from baseline (-16=0) after preload until time 15 during the test meal*/
lsmestimate condition*time
	'hypothesis 2: similar change from baseline in erythritol compared to sucralose at time 15 i.e. after preload and test meal' 0 1 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0,
	'hypothesis 2: lower increase from baseline in erythritol compared to sucrose at time 15 i.e. after preload and test meal' 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0,
	'hypothesis 2: similar change from baseline in erythritol compared to tap water at time 15 i.e. after preload and test meal' 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 / adjdfe=row divisor = 7 adjust=bon stepdown joint (label='hypotheses 2');
	/*hypothesis 2: difference between test solutions after preload until time 15 during the test meal*/


