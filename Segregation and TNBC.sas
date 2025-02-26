/**********************************************************************************************************************
SAS program for racialized economic segregation, treatment and outcomes in women with TNBC
Data sources:  SEER Research Plus database released in April 2019 
Exposure: racialized economic segregation
 - Index of Concentration at the Extremes (ICE) for each county was computed using the 2008-2012 American Community Surveys data
 - ICEi=(Bi-Wi)/Pi, where ICEi is the ICE index for county i, Bi the number of NHBs in the lowest percentiles (=20%) of household income, 
   Wi the number of NHWs in the highest percentiles (=80%) of household income, Pi the number of total population across all percentiles of household income at county i.
 - ICE has a range of -1 to 1.
 - ICE was categorized into quartiles based on its distribution among all TNBC cases, 
   with Quartile 1 representing the highest concentration of high-income NHW residents (most privileged) and 
   Quartile 4 representing the highest concentration of low-income NHB residents (most deprived). 
Outcome variables;
 - late-stage diagnosis
 - treatment, including surgery, radiotherapy, and chemotherapy
 - breast cancer mortality
 - all-cause mortality
Covariates: age, race/ethnicity, health insurance, marital status, SEER registries, rural locations, tumor grade.
Statistical models:
 - Logistic regression for the analyses of late-stage diagnosis and treatment
 - Fine and Gray subdistribution hazard models for the analysis of breast cancer mortality
 - Cox proportional hazards regression for the analysis of all-cause mortality
***********************************************************************************************************************/

/*read in SEER data using the algorithm provided by the SEER*/
data TNBC1;set casedat;
year_dx=Year_of_diagnosis;  /*year of diagnosis*/
age_dx=Age_at_diagnosis;  /*age at diagnosis*/

ethnic=OriginrecodeNHIAHispanicNonHis;   /*ethnicity and race*/
race1=RaceandoriginrecodeNHWNHBNHAIA;
race2=Race_ethnicity;

reg=SEER_registry;   /*registry*/
seq=Sequence_number;   /*sequence number*/
repsrc=Type_of_Reporting_Source;    /*report source*/
insurance=Insurance_Recode_2007;   /*insurance*/
mari1=Marital_status_at_diagnosis;    /*marital status*/
id=Patient_ID;   /*ID*/
fips=State_county;   /*fips*/
subtype=Breast_Subtype_2010;    /*subtypes*/
behavior=Behavior_code_ICD_O_3;   /*behavior code*/

/*stage*/
stage1=DerivedAJCCStageGroup6thed2004;
stage2=DerivedAJCCStageGroup7thed2010;
stage3=Derived_SEER_Cmb_Stg_Grp_2016;

/*lymph nodes*/
node1=DerivedAJCC_N_6th_ed_2004_2015;
node2=DerivedAJCC_N_7th_ed_2010_2015;
node3=Derived_SEER_Combined_N_2016;

/*treatment*/
surg1=RX_Summ_Surg_Prim_Site_1998;
surg2=Sitespecificsurgery19731997var;
rad1=Radiation_recode;
chemo=Chemotherapy_recode_yes_no_unk;

/*survival outcomes*/
time1=Survival_months;
sur1=SEERcausespecificdeathclassifi; /*cause specific death*/
sur2=SEERothercauseofdeathclassific; /*other causes of death*/
sur3=Vitalstatusrecodestudycutoffus; /*vital status*/ 

/*early FIPs of Hawaii were changed*/
                   CTY=fips; 
if fips=15911 then CTY=15001;
if fips=15912 then CTY=15003;
if fips=15913 then CTY=15005;
if fips=15914 then CTY=15007;
if fips=15915 then CTY=15009;
if fips=15900 then CTY=15009;

keep year_dx age_dx ethnic race1 race2 reg seq repsrc sex insurance mari1 stage1-stage3 node1-node3 grade surg1 surg2 rad1 chemo id time1 sur1 sur2 sur3 
     fips cty Breast_Subtype_2010;
run;

/*eligible TNBC cases*/
data TNBC2;set TNBC1;
 if 210<=year_dx<216;
 if 18<=age_dx<120;
 if sex=2;
 if seq in (0,1);
 if repsrc in (6,7) then delete;
 if .<time1<9999;
 if race1 in (1,2);
 if Breast_Subtype_2010=4;
 run;

 data TNBC3;set TNBC2;
 /*race*/
 if race1 in (1,2) then race=race1;
 label race='1NHW,2NHB';

 /*age*/
IF 18<=AGE_DX<40 then agegp=1;
IF 40<=AGE_DX<50 then agegp=2;
IF 50<=AGE_DX<60 then agegp=3;
IF 60<=AGE_DX<70 then agegp=4;
IF 70<=AGE_DX<80 then agegp=5;
IF 80<=AGE_DX then agegp=6;

/*tumor grade*/
if grade=1 then gradegp=1;
else if grade=2 then gradegp=2;
else if grade in (3,4) then gradegp=3;
else gradegp=4;

/*year*/
if 190<=year_dx<200 then year=1;
else if 200<=year_dx<210 then year=2;
else if 210<=year_dx then year=3; 

/*stage*/
if stage1 in (0,1,2) then stage=0;
if 10<=stage1<=24 then stage=1;
if 30<=stage1<=43 then stage=2;
if 50<=stage1<=63 then stage=3;
if 70<=stage1<=74 then stage=4;
if stage=. then do;
 if stage2 in (0,10,20) then stage=0;
 if 100<=stage2<241 then stage=1;
 if 300<=stage2<431 then stage=2;
 if 500<=stage2<631 then stage=3;
 if 700<=stage2<741 then stage=4;
 end;
if stage=. then do;
 if 1<=stage3<=3 then stage=0;
 if 4<=stage3<=12 then stage=1;
 if 13<=stage3<=18 then stage=2;
 if 19<=stage3<=24 then stage=3;
 if 25<=stage3<=30 then stage=4;
 end;
if stage=. then stage=5;

/*lymph nodes*/
if 0<=node1<=4 then node=0;  /*N0*/
if 10<=node1<=19 then node=1; /*N1*/
if 20<=node1<=29 then node=2; /*N2*/
if 30<=node1<=39 then node=3; /*N3*/
if node=. then do;
 if 0<=node2<=40 then node=0;
 if 100<=node2<=199 then node=1;
 if 200<=node2<=299 then node=2;
 if 300<=node2<=399 then node=3;
 end;
if node=. then do;
 if 2<=node3<=9 or 24<=node3<=28 then node=0;
 if 10<=node3<=13 or 29<=node3<=35 then node=1;
 if 14<=node3<=17 or 36<=node3<=39 then node=2;
 if 18<=node3<=21 or 40<=node3<=43 then node=3;
 end;
if node=. then node=4;

if node=0 then noden=0;
if node in (1,2,3) then noden=1;
if noden=. then noden=3;
label noden='node - 0 negative;1 positive';

/*Surgery*/
if surg1=0|surg2 in (0,1,2,3,5) then surgcat=3;
if 20<=surg1<=24|surg2 in (10,18,20,28) then surgcat=1;
if 30<=surg1<80|surg2 in (30,38,40,48,50,58,60,68) then surgcat=2;
if surg1 in (80,90)|surg2 in (80,90,98) then surgcat=4;
if surgcat=. then surgcat=5;
label surgcat='Surgery - 1.BCS;2.MAS;3.NO surg;4.surgery, NOS;5.missing';

/*radiation*/
 if 1<=rad1<=6 then rad=1;
 if rad1 in (0,7) then rad=0;
if rad=. then rad=3;
label rad='radiotherapy - 0 No;1 Yes;3 Missing';

/*insurance*/
 if insurance=1 then insurance2=1;
 if insurance=2 then insurance2=2;
 if insurance in (3,4) then insurance2=0;
 if insurance2=. then insurance2=3;
label insurance2='0 insured;1 uninsured;2 Medicaid;3 missing';

/*BC outcomes*/
if sur1=1 then event1=1;else event1=0; /*BC mortality*/
if sur3=0 then event2=1;else event2=0; /*overall mortality*/
if sur1=1 then event3=1;if sur2=1 then event3=2;if event3=. then event3=0;

/*marital status*/
if mari1 in (2,6) then mari2=0;if mari1 in (1,3,4,5) then mari2=1;if mari2=. then mari2=9;
label mari2='marital status - 0 married/unmarried partner;1 single/separated/divorced/widowed;9 missing';

firsttnbc=1;

keep id race age_dx agegp year_dx gradegp surgcat rad chemo firsttnbc time1 cty fips year sur1 sur2 sur3 reg surg1
     surg2 stage event1 event2 event3 insurance2 noden mari2;
run;proc sort;by cty;run;

/*read in county-level ICE scores, rural code, and diabetes prevalence rates;
  rural codes downloaded from the SEER website;
  diabetes prevalence rates downloaded from the CDC website*/
data cty3;set segr.srseg10_2;run;proc sort;by cty;run;
data ses;set seer.sesrural;cty=FIPs;run;proc sort;by cty;run;
data diabetes;set cdc.all_diabetespre;
 cty=County_FIPS;diabetes2010=Diagnosed_Diabetes_2010;diabetes2011=Diagnosed_Diabetes_2011;diabetes2012=Diagnosed_Diabetes_2012;
 diabetes2013=Diagnosed_Diabetes_2013;diabetes2014=Diagnosed_Diabetes_2014;diabetes2015=Diagnosed_Diabetes_2015;
 keep cty diabetes2010 diabetes2011 diabetes2012 diabetes2013 diabetes2014 diabetes2015;
 run;proc sort;by cty;run;
data diabetes1;set diabetes;if diabetes2010>.;keep cty diabetes2010;run;proc sort;by cty;run;
data diabetes2;set diabetes;if diabetes2011>.;keep cty diabetes2011;run;proc sort;by cty;run;
data diabetes3;set diabetes;if diabetes2012>.;keep cty diabetes2012;run;proc sort;by cty;run;
data diabetes4;set diabetes;if diabetes2013>.;keep cty diabetes2013;run;proc sort;by cty;run;
data diabetes5;set diabetes;if diabetes2014>.;keep cty diabetes2014;run;proc sort;by cty;run;
data diabetes6;set diabetes;if diabetes2015>.;keep cty diabetes2015;run;proc sort;by cty;run;
data diabetes7;merge diabetes1-diabetes6;by cty;run;

/*create a single dataset including all variables*/
data TNBC4;merge TNBC3 cty3 ses diabetes7;if firsttnbc=1;by cty;
segr1=ice10*(-1); /*ICE score*/
rural=RURAL13;
if year_dx=210 then diabetes=diabetes2010;if year_dx=211 then diabetes=diabetes2011;if year_dx=212 then diabetes=diabetes2012;
if year_dx=213 then diabetes=diabetes2013;if year_dx=214 then diabetes=diabetes2014;if year_dx=215 then diabetes=diabetes2015;
run;

/*categorize ICE scores and diabetes prevalence rates*/
proc rank data=TNBC4 out=TNBC5 groups=4 ties=low;
 var segr1 diabetes;
 ranks segr4 diabetesgp;
 run;

/*Excluding patients with unknown cancer stage*/
data TNBC5;set TNBC5;if segr4>.;if stage in (0,1,2,3,4);
 if reg in (1,21,25,26,31,35,41) then region=1;  /*West*/
 if reg in (2,44) then region=2;  /*Northeast*/
 if reg in (20,22) then region=3;  /*Midwest*/
 if reg in (23) then region=4;  /*Southwest*/
 if reg in (27,37,42,43,47) then region=5;  /*Southeast*/
 region1=region;if region in (4,5) then region1=6;
 if segr4 in (0,1) then segr2=0;if segr4 in (2,3) then segr2=1;
run;

/*descriptive statistics at the beginning of RESULTS*/
proc freq data=TNBC5;tables race insurance2 rural mari2 reg region1;run;
proc means data=TNBC5;var age_dx;run;

/*Table 1*/
proc means data=TNBC5;class segr4;var age_dx;run;
proc glm data=TNBC5;class segr4;model age_dx=segr4;run;
proc freq data=TNBC5;tables segr4*agegp segr4*race segr4*gradegp segr4*stage segr4*insurance2 segr4*rural segr4*mari2 segr4*region1/chisq;run;
proc means data=TNBC5 median min max;class segr4;var segr1;run;
proc univariate data=TNBC5;class segr4;var segr1;run;

/*eTable 1 - characteristics by race*/
proc freq data=tnbc5;tables race*agegp race*gradegp race*stage race*insurance2 race*rural race*mari2 race*region1/chisq;run;
proc ttest data=tnbc5;class race;var age_dx;run;

/*dataset for the analysis of breast cancer mortality and all-cause mortality*/
data TNBC6;set TNBC5;if stage in (1,2,3,4);
if rad=3 then rad=0;if insurance2=1 then insurance2=2;
/*ICE median values of cross-classified race and segregation groups*/ 
if race=1 then do;if segr4=0 then segrwb=-0.2300135;if segr4=1 then segrwb=-0.1526586;if segr4=2 then segrwb=-0.0987053;if segr4=3 then segrwb=-0.0019574;end;
if race=2 then do;if segr4=0 then segrwb=-0.2185822;if segr4=1 then segrwb=-0.1505774;if segr4=2 then segrwb=-0.0987053;if segr4=3 then segrwb=0.0510521;end;
time100=time1/12;
run;

/*Test for the PHR assumption*/
ods graphics on/loessobsmax=110000 antialiasmax=110000;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp sesg sizecat gradegp insurance2/param=ref ref=first;
 model time1*event1(0)=agegp;
 id cty;
 output out=propcheck ressch=schres;
 run;
proc sgplot data=propcheck;loess x=time1 y=schres/clm;run;
ods graphics off;

/*Figure 2 - association with BC mortality and all-cause mortality overall and by race*/
proc freq data=TNBC6;tables segr4*event3 race*segr4*event3 segr4*event2 race*segr4*event2;run;
proc univariate data=tnbc6;class segr4;var time100;run;
proc univariate data=tnbc6;class race segr4;var time100;run;
proc univariate data=tnbc6;var time1;run;

proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 race reg mari2/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segrwb stage chemo surgcat rad rural gradegp insurance2 race reg mari2/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 race reg mari2/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segrwb stage chemo surgcat rad rural gradegp insurance2 race reg mari2/risklimits;
 id cty;
 strata agegp;
 run;

proc sort data=TNBC6;by race;run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 reg mari2/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segrwb stage chemo surgcat rad rural gradegp insurance2 reg mari2/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 race mari2 race*segr4/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 reg mari2/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segrwb stage chemo surgcat rad rural gradegp insurance2 reg mari2/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 race mari2 race*segr4/risklimits;
 id cty;
 strata agegp;
 run;

/*eTable 2 - association with BC mortality and all-cause mortality overall and by race, adjusted for age and SEER registries*/
proc phreg data=TNBC6 covs(aggregate);
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event3(0)=segr4 race reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event3(0)=segrwb race reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event3(0)=segr4 reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event3(0)=segrwb reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event3(0)=segr4 race segr4*race reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event2(0)=segr4 race reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event2(0)=segrwb race reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event2(0)=segr4 reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event2(0)=segrwb reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 agegp cty race reg/param=ref ref=first;
 model time1*event2(0)=segr4 race segr4*race reg/risklimits;
 id cty;
 strata agegp;
 run;

/*Table 2 - Regional variations in the associations with breast cancer outcomes*/
proc sort data=TNBC6;by region1;run;
proc freq data=TNBC6;tables region1*segr2*event3 region1*segr2*event2;run;
proc univariate data=TNBC6;class region1 segr2;var time100;run;
proc phreg data=TNBC6 covs(aggregate);
 class segr2 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 region1/param=ref ref=first;
 model time1*event3(0)=segr2 stage chemo surgcat rad rural gradegp insurance2 race mari2 region1 segr2*region1/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by region1;
 class segr2 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 region1/param=ref ref=first;
 model time1*event3(0)=segr2 stage chemo surgcat rad rural gradegp insurance2 race mari2/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr2 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 region1/param=ref ref=first;
 model time1*event2(0)=segr2 stage chemo surgcat rad rural gradegp insurance2 race mari2 region1 segr2*region1/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by region1;
 class segr2 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 region1/param=ref ref=first;
 model time1*event2(0)=segr2 stage chemo surgcat rad rural gradegp insurance2 race mari2/risklimits;
 id cty;
 strata agegp;
 run;

/*eTable 3 - Associations with breast cancer mortality and overall mortality by urban and rural locations*/
data tnbc6;set tnbc6;
if segr4 in (0,1) then segr3=0;
if segr4 in (2,3) then segr3=segr4;
run;proc sort; by rural;run;

proc freq data=tnbc6;tables rural*segr3*event3 rural*segr3*event2;run;
proc univariate data=tnbc6;class rural segr3;var time100;run;
proc phreg data=TNBC6 covs(aggregate);
 class segr3 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr3 segr3*rural race stage chemo surgcat rad rural insurance2 gradegp mari2 reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by rural;
 class segr3 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr3 race stage chemo surgcat rad insurance2 gradegp mari2 reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by rural;
 class segr3 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr1 race stage chemo surgcat rad insurance2 gradegp mari2 reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr3 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr3 segr3*rural race stage chemo surgcat rad rural insurance2 gradegp mari2 reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by rural;
 class segr3 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr3 race stage chemo surgcat rad insurance2 gradegp mari2 reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by rural;
 class segr3 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr1 race stage chemo surgcat rad insurance2 gradegp mari2 reg/risklimits;
 id cty;
 strata agegp;
 run;

/*eTable 4 - Associations with breast cancer outcomes by cancer stage */
proc freq data=TNBC6;tables stage*segr4*event3 stage*segr4*event2;run;
proc univariate data=TNBC6;class stage segr4;var time100;run;
proc sort data=TNBC6;by stage;run;
proc phreg data=TNBC6 covs(aggregate);by stage;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr4 race chemo surgcat rad rural gradegp insurance2 mari2 reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by stage;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr1 race chemo surgcat rad rural gradegp insurance2 mari2 reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event3(0)=segr4 stage segr4*stage race chemo surgcat rad rural gradegp insurance2 mari2 reg/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by stage;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr4 race chemo surgcat rad rural gradegp insurance2 mari2 reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by stage;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr1 race chemo surgcat rad rural gradegp insurance2 mari2 reg/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2/param=ref ref=first;
 model time1*event2(0)=segr4 stage segr4*stage race chemo surgcat rad rural gradegp insurance2 mari2 reg/risklimits;
 id cty;
 strata agegp;
 run;

/*Figure 3 - Association with late-stage diagnosis*/
data TNBC7;set TNBC5;
if stage in (0,1,2) then stagec=0;if stage in (3,4) then stagec=1;
if segr4=0 then segr4=5;if segr2=0 then segr2=2;
run;proc sort;by race;run;
proc freq data=TNBC7;tables segr4*stagec race*segr4*stagec;run; 
/*call a SAS macro GLIMMIX to run multilevel logistic regression (https://support.sas.com/resources/papers/proceedings/proceedings/sugi27/p261-27.pdf)*/
%include 'C:\glmm800.sas'/nosource;
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr4 agegp rural insurance2 race reg mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr1 agegp rural insurance2 reg race mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(by race;
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr4 agegp rural insurance2 reg mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(by race;
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr1 agegp rural insurance2 reg mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr4 agegp rural insurance2 race reg mari2 segr4*race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

/*eTable 5 - Association with late-stage diagnosis by Census region*/
proc sort data=TNBC7;by region1;run;
proc freq data=TNBC7;tables region1*segr2*stagec;run; 
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(by region1;
     class segr2 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr2 agegp rural insurance2 race mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr2 agegp reg race cty rural stage gradegp insurance2 mari2 region1;
     model stagec =  segr2 agegp rural insurance2 race mari2 region1 segr2*region1/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(by region1;
     class segr2 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr2 agegp race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr2 agegp reg race cty rural stage gradegp insurance2 mari2 region1;
     model stagec =  segr2 agegp race region1 segr2*region1/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

/*Figure 4 - Associations with treatment*/  
/*surgery*/
data TNBC8;set TNBC5;if stage in (0,1,2,3) and surgcat in (1,2,3,4);
 if surgcat=3 then surgeryn=0;
 if surgcat in (1,2,4) then surgeryn=1;
 if segr4=0 then segr4=5;if segr2=0 then segr2=2;
run;
proc freq data=TNBC8;tables segr4*surgeryn;run; 
%glimmix(data=TNBC8,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model surgeryn =  segr4 agegp rural reg insurance2 race stage mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC8,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model surgeryn =  segr1 agegp rural reg insurance2 race stage mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

/*radiation*/
data TNBC9;set TNBC8;if surgcat=1|(surgcat=2 and noden=1);if rad in (0,1);run;
proc freq data=TNBC9;tables segr4*rad;run; 
%glimmix(data=TNBC9,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model rad =  segr4 agegp gradegp rural reg insurance2 stage surgcat race mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC9,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model rad =  segr1 agegp gradegp rural reg insurance2 stage surgcat race mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

/*chemotherapy*/
data TNBC10;set TNBC5;if stage in (1,2,3,4);if segr4=0 then segr4=5;run;proc sort;by race;run;
proc freq data=TNBC10;tables segr4*chemo;run; 
%glimmix(data=TNBC10,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model chemo =  segr4 agegp gradegp rural reg insurance2 stage race surgcat mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC10,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model chemo =  segr1 agegp gradegp rural reg insurance2 stage race surgcat mari2/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

/*eTable 6 - Association with late-stage diagnosis in the simple model*/
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr4 agegp race reg/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr1 agegp reg race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
proc sort data=TNBC7;by race;run;
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(by race;
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr4 agegp reg/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(by race;
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr1 agegp reg/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC7,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model stagec =  segr4 agegp race reg segr4*race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

/*eTable 7 - Association with treatment in the simple model*/
%glimmix(data=TNBC8,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model surgeryn =  segr4 agegp reg race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC8,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 mari2;
     model surgeryn =  segr1 agegp reg race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

%glimmix(data=TNBC9,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model rad =  segr4 agegp reg race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC9,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model rad =  segr1 agegp reg race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

%glimmix(data=TNBC10,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model chemo =  segr4 agegp reg race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);
%glimmix(data=TNBC10,procopt=covtest,stmts=%str(
     class segr4 agegp reg race cty rural stage gradegp insurance2 surgcat mari2;
     model chemo =  segr1 agegp reg race/ solution cl;
     random intercept/sub=cty;
     ), error=binomial,link=logit, maxit=20);

/*eTable 8 - Associations with breast cancer mortality and overall mortality, derived from the models further adjusted for county-level diabetes prevalence*/
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event3(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 reg race mari2 diabetesgp/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event3(0)=segr1 stage chemo surgcat rad rural gradegp insurance2 reg race mari2 diabetesgp/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc sort data=TNBC6;by race;run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event3(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 reg mari2 diabetesgp/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event3(0)=segrwb stage chemo surgcat rad rural gradegp insurance2 reg mari2 diabetesgp/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event3(0)=segr4 segr4*race stage chemo surgcat rad rural gradegp insurance2 reg race mari2 diabetesgp/eventcode=1 risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event2(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 reg race mari2 diabetesgp/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event2(0)=segr1 stage chemo surgcat rad rural gradegp insurance2 reg race mari2 diabetesgp/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event2(0)=segr4 stage chemo surgcat rad rural gradegp insurance2 reg mari2 diabetesgp/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);by race;
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event2(0)=segrwb stage chemo surgcat rad rural gradegp insurance2 reg mari2 diabetesgp/risklimits;
 id cty;
 strata agegp;
 run;
proc phreg data=TNBC6 covs(aggregate);
 class segr4 cty race stage chemo surgcat rad rural reg agegp gradegp insurance2 mari2 diabetesgp/param=ref ref=first;
 model time1*event2(0)=segr4 segr4*race stage chemo surgcat rad rural gradegp insurance2 reg race mari2 diabetesgp/risklimits;
 id cty;
 strata agegp;
 run;
 /*causal mediation analysis to quantify the contribution of segregation to the racial differences in BC outcomes and late stage diagnosis*/
 /*call a SAS macro %MEDIATION created by Valeri L and VanderWeele TJ (SAS macro for causal mediation analysis with survival data. Epidemiology 2015;26:e23-4.)*/
 %include 'C:\mediation.sas';
data TNBC6a;set TNBC6;
 if agegp=2 then agegp2=1;else agegp2=0;
 if agegp=3 then agegp3=1;else agegp3=0;
 if agegp=4 then agegp4=1;else agegp4=0;
 if agegp=5 then agegp5=1;else agegp5=0;
 if agegp=6 then agegp6=1;else agegp6=0;

 if insurance2=2 then insurance2a=1;else insurance2a=0;
 if insurance2=3 then insurance2b=1;else insurance2b=0;

 if mari2=1 then mari2a=1;else mari2a=0;
 if mari2=9 then mari2b=1;else mari2b=0;

 if stage=1 then stage_a=1;else stage_a=0; if stage=2 then stage_b=1;else stage_b=0;
 if stage=3 then stage_c=1;else stage_c=0;

 if gradegp=2 then gradegp2=1;else gradegp2=0;
 if gradegp=3 then gradegp3=1;else gradegp3=0;
 if gradegp=4 then gradegp4=1;else gradegp4=0;

 if surgeryn=1 then surgeryn1=1;else surgeryn1=0;
 if surgeryn=2 then surgeryn2=1;else surgeryn2=0;
run;
%mediation(data=TNBC6a,yvar=time1,avar=race,mvar=segr1,
           cvar=agegp2 agegp3 agegp4 agegp5 agegp6 insurance2a insurance2b mari2a mari2b stage_a stage_b stage_c gradegp2 gradegp3 gradegp4 
                surgeryn1 surgeryn2 chemo rad rural,
           a0=0,a1=1,m=-1,yreg=survCox,mreg=linear,interaction=true,casecontrol=,output=,c=,boot=,cens=event1);
run;
%mediation(data=TNBC6a,yvar=time1,avar=race,mvar=segr1,
           cvar=agegp2 agegp3 agegp4 agegp5 agegp6 insurance2a insurance2b mari2a mari2b stage_a stage_b stage_c gradegp2 gradegp3 gradegp4 
                surgeryn1 surgeryn2 chemo rad rural,
           a0=0,a1=1,m=-1,yreg=survCox,mreg=linear,interaction=false,casecontrol=,output=,c=,boot=,cens=event2);
run;

data TNBC7a;set TNBC7;
 if agegp=2 then agegp2=1;else agegp2=0;
 if agegp=3 then agegp3=1;else agegp3=0;
 if agegp=4 then agegp4=1;else agegp4=0;
 if agegp=5 then agegp5=1;else agegp5=0;
 if agegp=6 then agegp6=1;else agegp6=0;

 if insurance2=2 then insurance2a=1;else insurance2a=0;
 if insurance2=3 then insurance2b=1;else insurance2b=0;

 if mari2=1 then mari2a=1;else mari2a=0;
 if mari2=9 then mari2b=1;else mari2b=0;
run;
%mediation(data=TNBC7a,yvar=stagec,avar=race,mvar=segr1,
           cvar=agegp2 agegp3 agegp4 agegp5 agegp6 insurance2a insurance2b mari2a mari2b rural,
           a0=0,a1=1,m=-1,yreg=logistic,mreg=linear,interaction=false,casecontrol=,output=,c=,boot=,cens=);
run;

/*Figure 1 - eligible cases included in the analyses*/
data elig1;set TNBC1;
 if 210<=year_dx<216;
 if sex=2;
 if seq in (0,1);
 if 18<=age_dx<120;
 if Breast_Subtype_2010=4;
 label race1='1 = "Non-Hispanic White"
    2 = "Non-Hispanic Black"
    3 = "Non-Hispanic American Indi;an/Alaska Native"
    4 = "Non-Hispanic Asian or Pacific Islander"
    5 = "Hispanic (All Races)"
    9 = "Non-Hispanic Unknown Race"'
run;proc freq;tables race1;run;
data elig2;set elig1;
 if race1 in (1,2);
 if repsrc in (6,7) then delete;
 /*stage*/
if stage1 in (0,1,2) then stage=0;
if 10<=stage1<=24 then stage=1;
if 30<=stage1<=43 then stage=2;
if 50<=stage1<=63 then stage=3;
if 70<=stage1<=74 then stage=4;
if stage=. then do;
 if stage2 in (0,10,20) then stage=0;
 if 100<=stage2<241 then stage=1;
 if 300<=stage2<431 then stage=2;
 if 500<=stage2<631 then stage=3;
 if 700<=stage2<741 then stage=4;
 end;
if stage=. then do;
 if 1<=stage3<=3 then stage=0;
 if 4<=stage3<=12 then stage=1;
 if 13<=stage3<=18 then stage=2;
 if 19<=stage3<=24 then stage=3;
 if 25<=stage3<=30 then stage=4;
 end;
if stage=. then stage=5;
 *if stage in (0,1,2,3,4);
 TNBC=1;
 run;proc freq;tables stage;run;
data elig3;set elig2;if stage in (0,1,2,3,4);run; proc sort;by cty;run;
data elig3;merge elig3 cty3;if TNBC=1;by cty;
segr1=ice10*(-1);
run;proc univariate;var segr1;run;
data elig4;set elig3;if segr1>.;run;  
proc freq data=elig4;tables race1 stage;run;   /*the cases eligible for the analysis of late-stage diagnosis*/

data elig5;set elig4;if stage in (1,2,3,4);run;
proc freq;tables race1;run;   /*the cases eligible for the analysis of chemotherapy and survival outcomes*/

data elig6;set elig4;if stage in (0,1,2,3);
if surg1=0|surg2 in (0,1,2,3,5) then surgcat=3;
if 20<=surg1<=24|surg2 in (10,18,20,28) then surgcat=1;
if 30<=surg1<80|surg2 in (30,38,40,48,50,58,60,68) then surgcat=2;
if surg1 in (80,90)|surg2 in (80,90,98) then surgcat=4;
if surgcat=. then surgcat=5;
label surgcat='Surgery - 1.BCS;2.MAS;3.NO surg;4.surgery, NOS;5.missing';

if 0<=node1<=4 then node=0;  /*N0*/
if 10<=node1<=19 then node=1; /*N1*/
if 20<=node1<=29 then node=2; /*N2*/
if 30<=node1<=39 then node=3; /*N3*/
if node=. then do;
 if 0<=node2<=40 then node=0;
 if 100<=node2<=199 then node=1;
 if 200<=node2<=299 then node=2;
 if 300<=node2<=399 then node=3;
 end;
if node=. then do;
 if 2<=node3<=9 or 24<=node3<=28 then node=0;
 if 10<=node3<=13 or 29<=node3<=35 then node=1;
 if 14<=node3<=17 or 36<=node3<=39 then node=2;
 if 18<=node3<=21 or 40<=node3<=43 then node=3;
 end;
if node=. then node=4;

if node=0 then noden=0;
if node in (1,2,3) then noden=1;
if noden=. then noden=3;
label noden='lymph node - 0 negative;1 positive';
run;
proc freq;tables surgcat;run;
data elig7;set elig6;if surgcat in (1,2,3,4);run;   
proc freq;tables surgcat;run; /*the cases eligible for the analysis of surgery*/

data elig8;set elig7;if surgcat in (1,2);
/*radiation*/
 if 1<=rad1<=6 then rad=1;
 if rad1 in (0,7) then rad=0;
if rad=. then rad=3;
run;
proc freq;tables noden*surgcat;run;
data elig9;set elig8;if surgcat=1|(surgcat=2 and noden in (1,2));run;
proc freq;tables rad;run; 
data elig10;set elig9;if rad in (0,1);run;
proc freq;tables rad;run;  /*the cases eligible for the analysis of radiotherapy*/
