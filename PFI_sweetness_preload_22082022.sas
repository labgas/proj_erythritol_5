/*Import Excel File*/
%web_drop_table(sweetness);


FILENAME REFFILE '/home/u50127452/sasuser.v94/PolyFoodIntake/SAS_PolyFoodIntake_02_02_2022.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=sweetness;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=sweetness; RUN;


%web_open_table(sweetness);

/*---------------------------------------------------*/
/* CHECK DISTRIBUTION SWEETNESS PRELOAD				*/
/*---------------------------------------------------*/
proc univariate data=sweetness;
var sweetness_preload;
histogram sweetness_preload / normal(mu=est sigma=est) lognormal (sigma=est theta=est zeta=est); 
run;
/*transformation needed*/

/* box-cox transformation */
data sweetness;
set sweetness;
z=0;
run;
/* adds variable z with all zeros, needed in proc transreg */

proc transreg data=sweetness maxiter=0 nozeroconstant;
   	model BoxCox(sweetness_preload/parameter=1) = identity(z);
run;
/* check lambda in output, in this case 1
parameter is constant to make all values positive if there are negative values, hence parameter = |minimum|, see below */

data sweetness;
set sweetness;
bc_sweetness_preload = (sweetness_preload**1 -1)/1;
run;
/* boxcox formula, 1 is lambda*/

/* check normality of box-cox transformed variable */
proc univariate data=sweetness;
var bc_sweetness_preload;
histogram bc_sweetness_preload / normal (mu=est sigma=est);
run;
/**/

/*Mixed model adjusted for normality*/
proc mixed data=sweetness;
class subject condition;
model bc_sweetness_preload = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;
