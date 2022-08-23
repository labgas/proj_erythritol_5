/*-------------------------------*/
/* IMPORT DATA FROM EXCEL FILE   */
/*-------------------------------*/

%web_drop_table(liking_testmeal);


FILENAME REFFILE '/home/u50127452/sasuser.v94/PolyFoodIntake/SAS_PolyFoodIntake_05_10_2021.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=liking_testmeal;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=liking_testmeal; RUN;


%web_open_table(liking_testmeal);

/*---------------------------------------------------*/
/* CHECK DISTRIBUTION LIKING TEST MEAL			*/
/*---------------------------------------------------*/
proc univariate data=liking_testmeal;
var liking_testmeal;
histogram liking_testmeal / normal; 
run;
/*Kolmogorov p-value<0.150*/

/*Mixed model NOT adjusted for normality*/
proc mixed data=liking_testmeal;
class subject condition;
model liking_testmeal = condition / solution;
repeated condition / subject = subject type=un r rcorr;
lsmeans condition / diff = all adjust=tukey;
run;
