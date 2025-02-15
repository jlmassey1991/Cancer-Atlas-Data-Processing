

/****************************************************************************


STEPS FOR UPDATING CANCER ATLAS
Version: 2023
Editor: Jason Massey
Date Last Edited: 3/23/2023


/*****************************************************************************
 Step 1: Replace library with correct pathname to import census data from Social Explorer and cancer data from CDC  
 Step 2: If needed update code 
 Step 3: Check new atlas and verify with old
 Step 4: Export final file with correct pathname to be merged with shapefile 
 Step 5: Make a copy of data processing code for next update and replace Old Atlas Dataset with updated atlas dataset  

****************************************************************************/






/* 

 (A) Old Atlas Data 

*/



*Old Atlas Dataset for commparison;
*AFTER COPYING CURRENT DATA PROCESSING CODE, VERIFY PATHNAME AND REPLACE WITH MOST RECENT VERSION OF ATLAS DATASET;
proc import 
    dbms=dbf
    datafile= "XXXX.dbf"
    out=atlas_old;
run;

*Drop Lables and Formats;
proc datasets lib=work;
  modify atlas_old;
  attrib _all_ label='';
run;

*Keep relevant variables from old atlas;
data atlas_old2;
set atlas_old;
keep ObjectID NAME STATE_NAME STATE_FIPS CNTY_FIPS FIPS MStateID ;
rename FIPS = Geo_FIPS ;
run;

*Sort old atlas;
proc sort data = atlas_old2;
by Geo_FIPS;
run;






/*******************************************************************************************************************

 Step 1: Replace library with correct pathname and import cancer data from CDC and census data from Social Explorer

********************************************************************************************************************/

*Library;                    
* REPLACE WITH CORRECT PATHNAME;
libname atlas "C:\Users\JasonMassey\OneDrive - American Cancer Society\Documents\Misc\Cancer_Atlas_Updates\2023_Updates";
run;

*Import Census Data;
data ses_data;
set atlas.SES_2023;			*<--- REPLACE WITH NEW CENSUS DATA;
run;

*Drop Labels and Formats;
proc datasets lib=work;
  modify ses_data;
  attrib _all_ label='';
run;

*Import Cancer Data;
data cancer_data;
set atlas.byarea_county;	*<--- REPLACE WITH NEW CANCER DATA;
run;

*Drop Labels and Formats;
proc datasets lib=work;
  modify cancer_data;
  attrib _all_ label='';
run;
 





/*******************************************************************************************************************

 Step 2: If needed update code

********************************************************************************************************************/





/* 

 (B) Census Data from Am. Com. Survey 

*/

*Rename vars;
data census_2;     
set ses_data;            
length Geo_FIPS $ 5;
Geo_FIPS = FIPS;

rename 
A04001_001 = TotPop 
PCT_A04001_003 = PWhitePCT 
PCT_A04001_004 = PBlackPCT 
PCT_A04001_005 = PNativePCT
PCT_A04001_006 = PAsianPCT 
PCT_A04001_007 = PPacificPC
PCT_A17005_003 = PUnemploye
PCT_A13003B_002 = PPovertyPC
A14006_001 = PMedHHInco;      

PNoBachelo = sum(PCT_A12001_002 + PCT_A12001_003 + PCT_A12001_004);

run;

*Keep relevant variables;
data census_3;
set census_2;
keep 
Geo_FIPS
PWhitePCT 
PBlackPCT 
PNativePCT
PAsianPCT 
PPacificPC
PUnemploye
PPovertyPC
PMedHHInco
PNoBachelo
 ;
 run;







/*

(C) Cancer Data 

*/


*Updating/renaming cancer sites;
data cancer_data2;
set cancer_data;

if SITE = 'All Cancer Sites Combined' then cancer2 = 'All Malignant Cancers';
if SITE = 'Cervix' then cancer2 = 'Cervix Uteri';
if SITE = 'Colon and Rectum' then cancer2 = 'Colorectum';
if SITE = 'Corpus and Uterus, NOS' then cancer2 = 'Corpus and Uterus, NOS';
if SITE = 'Esophagus' then cancer2 = 'Esophagus ';
if SITE = 'Hodgkin Lymphoma' then cancer2 = 'Lymphoma';
if SITE = 'Kidney and Renal Pelvis' then cancer2 = 'Kidney and Renal Pelvis';
if SITE = 'Leukemias' then cancer2 = 'Leukemia';
if SITE = 'Liver and Intrahepatic Bile Duct' then cancer2 = 'Liver and Intrahepatic Bile Duct';
if SITE = 'Lung and Bronchus' then cancer2 = 'Lung and Bronchus';
if SITE = 'Male and Female Breast' then cancer2 = 'Breast';
if SITE = 'Ovary' then cancer2 = 'Ovary';
if SITE = 'Pancreas' then cancer2 = 'Pancreas';
if SITE = 'Prostate' then cancer2 = 'Prostate';
if SITE = 'Stomach' then cancer2 = 'Stomach';
if SITE = 'Urinary Bladder' then cancer2 = 'Urinary Bladder';

run;


*Sorting;
proc sort data = cancer_data2;        
by Sex ;
run;

*Create Fips Code;
data cancer_data3;
set cancer_data2;                     
format Crd_Rate Age_Rate Best12.;
Crd_Rate = CRUDE_RATE;
Age_Rate = AGE_ADJUSTED_RATE;

length Geo_FIPS $ 5;
Geo_FIPS = strip(scan(AREA,2,'()'));
run;

proc sort data=cancer_data3;
by STATE ;
run;




/*

5-Yr Incidence: Non-Sex Specific Sites (all sexes; IE: male and female breast cancer included) 

*/

/* I need to select incidence only, and flip the data into a wide format*/
data incidence2;
set cancer_data3;
where EVENT_TYPE = "Incidence" and sex = "Male and Female" and RACE = "All Races" ;
run;

data incidence2;
set incidence2;
where SITE = "All Cancer Sites Combined" or SITE = "Cervix" or SITE = "Colon and Rectum" or
SITE = "Corpus and Uterus, NOS" or SITE = "Esophagus" or SITE = "Hodgkin Lymphoma" or
SITE = "Kidney and Renal Pelvis" or SITE = "Leukemias" or SITE = "Liver and Intrahepatic Bile Duct" or
SITE = "Lung and Bronchus" or SITE = "Male and Female Breast" or SITE = "Male and Female Breast, <i>in situ</i>" or
SITE = "Non-Hodgkin Lymphoma" or SITE = "Ovary" or SITE = "Pancreas" or SITE = "Prostate" or SITE = "Stomach" or SITE = "Urinary Bladder";
run;

proc sort data=incidence2;
by Geo_FIPS ;
run;

PROC TRANSPOSE data= incidence2 out= incidence_wide ;
    BY Geo_FIPS ;
    *COPY Sex;
    *ID State_county;
    VAR SITE POPULATION	COUNT Crd_Rate Age_Rate;
RUN;

data incidence_wide_ar;
set incidence_wide;
where _NAME_ = "SITE" or _NAME_ = "Age_Rate";
run;

data incidence_wide_cnt;
set incidence_wide;
where _NAME_ = "SITE" or _NAME_ = "COUNT";
run;



*Rename Columns tables ; 

*AR;
data incidence_wide_ar_2 ;
set incidence_wide_ar; 
IAll_AR =   COL1*1 ;
ICRC_AR =   COL3*1 ;
ILiver_AR = COL9*1 ;
ILung_AR =  COL10*1;
INHL_AR =   COL13*1;
IPancr_AR = COL15*1; 

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL18;

run;


*Count;
data incidence_wide_cnt_2;
set incidence_wide_cnt;
IAll_cnt =   COL1*1 ;
ICRC_cnt =   COL3*1 ;
ILiver_cnt = COL9*1 ;
ILung_cnt =  COL10*1;
INHL_cnt =   COL13*1;
IPancr_cnt = COL15*1; 

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL18;

run;




/*

5-y incidence data - Sex Specific Sites (Include Single Sex Values Only. IE: Excluding Male Breast Cancer etc. ) 

*/

data incidence_mf;
set cancer_data3;
where  EVENT_TYPE = "Incidence" and sex ^= "Male and Female" and RACE = "All Races";
run;

data incidence_mf2;
set incidence_mf;
where SITE = "Cervix" or SITE = "Corpus and Uterus, NOS" or SITE = "Female Breast" or SITE = "Female Breast, <i>in situ</i>"
or SITE = "Ovary" or SITE = "Prostate" ;
run;

proc sort data=incidence_mf2;
by Geo_FIPS ;
run;

PROC TRANSPOSE data=incidence_mf2 out=incidence_mf_wide ;
    BY Geo_FIPS ;
    *COPY Sex;
    *ID State_county;
    VAR SITE POPULATION	COUNT Crd_Rate Age_Rate;
RUN;

data incidence_mf_wide_ar;
set incidence_mf_wide;
where _NAME_ = "SITE" or _NAME_ = "Age_Rate";
run;

data incidence_mf_wide_cnt;
set incidence_mf_wide;
where _NAME_ = "SITE" or _NAME_ = "COUNT";
run;



*Renaming columns for tables ;

*AR;
data incidence_mf_wide_ar_2 ;
set incidence_mf_wide_ar;
 ICervix_AR=  COL1*1 ;
 ICorpUte_AR= COL2*1 ;
 IFemBC_AR =  COL3*1 ;
 IFemBCis_AR= COL4*1 ;
 IOvary_AR =  COL5*1 ;
 Iprost_AR=   COL6*1 ;
;

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL6 ;

run;

*Count;
data incidence_mf_wide_cnt_2;
set incidence_mf_wide_cnt;
 ICervix_cnt=  COL1*1 ;
 ICorpUte_cnt= COL2*1 ;
 IFemBC_cnt =  COL3*1 ;
 IFemBCis_cnt= COL4*1 ;
 IOvary_cnt =  COL5*1 ;
 Iprost_cnt=   COL6*1 ;
;

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL6 ;

run;




/*

5-Yr mortality: Non-Sex Specific Sites (all sexes; IE: male and female breast cancer included) 

*/

/* I need to select mortality only, and flip the data into a wide format*/
data mortality2;
set cancer_data3;
where EVENT_TYPE = "Mortality" and sex = "Male and Female" and RACE = "All Races" ;
run;

data mortality2;
set mortality2;
where SITE = "All Cancer Sites Combined" or SITE = "Cervix" or SITE = "Colon and Rectum" or
SITE = "Corpus and Uterus, NOS" or SITE = "Esophagus" or SITE = "Hodgkin Lymphoma" or
SITE = "Kidney and Renal Pelvis" or SITE = "Leukemias" or SITE = "Liver and Intrahepatic Bile Duct" or
SITE = "Lung and Bronchus" or SITE = "Male and Female Breast" or SITE = "Male and Female Breast, <i>in situ</i>" or
SITE = "Non-Hodgkin Lymphoma" or SITE = "Ovary" or SITE = "Pancreas" or SITE = "Prostate" or SITE = "Stomach" or SITE = "Urinary Bladder";
run;

proc sort data=mortality2;
by Geo_FIPS ;
run;

PROC TRANSPOSE data= mortality2 out= mortality_wide ;
    BY Geo_FIPS ;
    *COPY Sex;
    *ID State_county;
    VAR SITE POPULATION	COUNT Crd_Rate Age_Rate;
RUN;

data mortality_wide_ar;
set mortality_wide;
where _NAME_ = "SITE" or _NAME_ = "Age_Rate";
run;

data mortality_wide_cr;
set mortality_wide;
where _NAME_ = "SITE" or _NAME_ = "Crd_Rate";
run;

data mortality_wide_pop;
set mortality_wide;
where _NAME_ = "SITE" or _NAME_ = "POPULATION";
run;

data mortality_wide_cnt;
set mortality_wide;
where _NAME_ = "SITE" or _NAME_ = "COUNT";
run;




*Rename Columns for tables ; 

*AR;
data mortality_wide_ar_2 ;
set mortality_wide_ar; 
 MAll_AR    = COL1*1 ;
 MCRC_AR    = COL3*1 ;
 MLiver_AR  = COL9*1 ;
 MLung_AR   = COL10*1;
 MNHL_AR    = COL13*1;
 MPancr_AR  = COL15*1;

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL18;

run;

*Count;
data mortality_wide_cnt_2;
set mortality_wide_cnt;
 MAll_cnt    = COL1*1 ;
 MCRC_cnt   = COL3*1 ;
 MLiver_cnt  = COL9*1 ;
 MLung_cnt   = COL10*1;
 MNHL_cnt    = COL13*1;
 MPancr_cnt  = COL15*1;

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL18;

run;




/*

5-y mortality data - Sex Specific Sites (Include Single Sex Values Only. IE: Excluding Male Breast Cancer etc. ) 

*/

data mortality_mf;
set cancer_data3;
where  EVENT_TYPE = "Mortality" and sex ^= "Male and Female" and RACE = "All Races";
run;

data mortality_mf2;
set mortality_mf;
where SITE = "Cervix" or SITE = "Corpus and Uterus, NOS" or SITE = "Female Breast" or SITE = "Female Breast, <i>in situ</i>"
or SITE = "Ovary" or SITE = "Prostate" ;
run;

proc sort data=mortality_mf2;
by Geo_FIPS ;
run;

PROC TRANSPOSE data=mortality_mf2 out=mortality_mf_wide ;
    BY Geo_FIPS ;
    *COPY Sex;
    *ID State_county;
    VAR SITE POPULATION	COUNT Crd_Rate Age_Rate;
RUN;

data mortality_mf_wide_ar;
set mortality_mf_wide;
where _NAME_ = "SITE" or _NAME_ = "Age_Rate";
run;

data mortality_mf_wide_cr;
set mortality_mf_wide;
where _NAME_ = "SITE" or _NAME_ = "Crd_Rate";
run;

data mortality_mf_wide_pop;
set mortality_mf_wide;
where _NAME_ = "SITE" or _NAME_ = "POPULATION";
run;

data mortality_mf_wide_cnt;
set mortality_mf_wide;
where _NAME_ = "SITE" or _NAME_ = "COUNT";
run;



*Renaming columns for tables ;

*AR;
data mortality_mf_wide_ar_2 ;
set mortality_mf_wide_ar;  
 MCervix_AR  = COL1*1;
 MCorpUte_AR = COL2*1;
 MFemBC_AR   = COL3*1;
 MOvary_AR   = COL4*1;
 Mprost_AR   = COL5*1;

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL5  ;

run;


*Count;
data mortality_mf_wide_cnt_2;
set mortality_mf_wide_cnt; 
  MCervix_cnt   =COL1*1;
  MCorpUte_cnt  =COL2*1;
  MFemBC_cnt    =COL3*1;
  MOvary_cnt    =COL4*1;
  Mprost_cnt    =COL5*1;

if _NAME_ = "SITE" then delete ;
drop _NAME_ COL1-COL5  ;

run;





/*
 
(D) 

- Merge Old Atlas, Census, and Cancer Data - 

{ Old Atlas Data, 
  Census Data,
  Incidence Allsexes, Incidence Single Sexes, Mortality Allsexes, Mortality Single Sexes }

*/

data atlas_new;

   merge 

		 atlas_old2 
		 census_3
		 incidence_wide_ar_2   incidence_wide_cnt_2
		 incidence_mf_wide_ar_2   incidence_mf_wide_cnt_2
		 mortality_wide_ar_2   mortality_wide_cnt_2
		 mortality_mf_wide_ar_2   mortality_mf_wide_cnt_2;

   by Geo_FIPS;

*Rename Geo_FIPS to FIPS to match Old Atlas ;
   rename Geo_FIPS = FIPS ;

run;

 




/******************************************************************************************************************

 Step 3: Check table, variables names, types, formats, and frequencies. Make sure matches old atlas structure

*******************************************************************************************************************/

*Copy contents to excel and compare duplicate names etc. ;

proc contents data = atlas_old;
run;

proc contents data = atlas_new;
run;






/******************************************************************************************************************

 Step 4: Export final file with correct pathname to be merged with shapefile 

*******************************************************************************************************************/


/*

PROC EXPORT DATA= atlas_new
            OUTFILE= " [ *** PATHNAME GOES HERE *** ] \atlas_new.dbf"
            DBMS=DBF replace;
RUN;

*/






/********************************************************************************************************************

Step 5: Make a copy of data processing code for next update and replace Old Atlas Dataset with updated atlas dataset 

*********************************************************************************************************************/









