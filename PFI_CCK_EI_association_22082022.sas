/* Generierter Code (IMPORT) */
/* Quelldatei: PFI_associations.xlsx */
/* Quellpfad: /home/u50127452/sasuser.v94/PolyFoodIntake */
/* Code generiert am: 28.04.22 11:45 */

%web_drop_table(EI_CCK_asso);


FILENAME REFFILE '/home/u50127452/sasuser.v94/PolyFoodIntake/SAS_PFI_associations.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=EI_CCK_asso;
	GETNAMES=YES;
	SHEET="Associations";
RUN;

PROC CONTENTS DATA=EI_CCK_asso; RUN;


%web_open_table(EI_CCK_asso);

/*Association between post-preload timpoint -1 of CCK and energy intake
EI_E_S = Difference of Energy Intake between Erythritol and Sucrose
CCK_E_S = Difference of CCK between Erythritol and Sucrose at timepoint -1
Erythritol*/
PROC CORR DATA=EI_CCK_asso plots=scatter spearman;
    VAR EI_E_S CCK_E_S;
RUN;

/*Sucralose*/
PROC CORR DATA=EI_CCK_asso plots=scatter spearman;
    VAR EI_E_SL CCK_E_SL;
RUN;


/*Tap Water*/
PROC CORR DATA=EI_CCK_asso plots=scatter spearman;
    VAR EI_E_W CCK_E_W;
RUN;
