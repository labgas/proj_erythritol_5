/*-------------------------------*/
/* IMPORT DATA FROM EXCEL FILE   */
/*-------------------------------*/

%web_drop_table(liking_preload);


FILENAME REFFILE '/home/u50127452/sasuser.v94/PolyFoodIntake/SAS_PolyFoodIntake_05_10_2021.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=liking_preload;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=liking_preload; RUN;


%web_open_table(liking_preload);

/*---------------------------------------------------*/
/* CHECK DISTRIBUTION LIKING PRELOAD   				*/
/*---------------------------------------------------*/
proc univariate data=liking_preload;
var liking_preload;
histogram liking_preload / normal; 
run;
/*Kolmogorov p-value<0.033 --> no transformation*/

/* box-cox transformation */
data liking_preload;
set liking_preload;
z=0;
run;
/* adds variable z with all zeros, needed in proc transreg */

proc transreg data=liking_preload maxiter=0 nozeroconstant;
   	model BoxCox(liking_preload/parameter=9) = identity(z);
run;
/* check lambda in output, in this case 1
parameter is constant to make all values positive if there are negative values, hence parameter = |minimum|, see below */

data liking_preload;
set liking_preload;
bc_liking_preload = (liking_preload**9 -1)/1;
run;
/* boxcox formula, 1 is lambda*/

/* check normality of box-cox transformed variable */
proc univariate data=liking_preload;
var bc_liking_preload;
histogram bc_liking_preload / normal (mu=est sigma=est);
run;
/**/

/*Mixed model NOT adjusted for normality*/
proc mixed data=liking_preload;
class subject condition;
model liking_preload = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;


/*Mixed model adjusted for normality*/
proc mixed data=liking_preload;
class subject condition;
model bc_liking_preload = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;
/*stopped because of infinite likelihood*/