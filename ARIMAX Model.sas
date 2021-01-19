libname ts1 "/opt/sas/home/smbirade/sasuser.viya/";
proc import datafile = '/opt/sas/home/smbirade/sasuser.viya/Ozone_Raleigh2.csv'
 out = work.ozone_raleigh2
 dbms = CSV
replace
 ;
run;


proc import datafile = '/opt/sas/home/smbirade/sasuser.viya/Raleigh_weather.csv'
 out = work.weather
 dbms = CSV
replace
 ;
run;

proc import datafile = '/opt/sas/home/smbirade/sasuser.viya/SO2_Raleigh.csv'
 out = work.SO2
 dbms = CSV
replace
 ;
run;

proc import datafile = '/opt/sas/home/smbirade/sasuser.viya/NO_Raleigh.csv'
 out = work.NO
 dbms = CSV
replace
 ;
run;

proc import datafile = '/opt/sas/home/smbirade/sasuser.viya/CO_Raleigh.csv'
 out = work.CO
 dbms = CSV
replace
 ;
run;

* Visualize the data (Ozone) !!!! ;
proc sgplot data=ozone_raleigh2;
	series x=date y='Daily Max 8-hour Ozone Concentra'n;
run;
quit;

proc timeseries data=work.ozone_raleigh2 plots=(series decomp sc) seasonality=365;
	var 'Daily Max 8-hour Ozone Concentra'n;
run;

* Visualize the data (Precip) !!!! ;
proc sgplot data=weather;
	series x=date y=PRCP;
run;
quit;
* Visualize the data (Snow) !!!! ;
proc sgplot data=weather;
	series x=date y=snow;
run;
quit;

* Visualize the data (Snow Depth) !!!! ;
proc sgplot data=weather;
	series x=date y=snwd;
run;
quit;
* Visualize the data (Avreage Wind Speed) !!!! ;
proc sgplot data=weather;
	series x=date y=AWND;
run;
quit;

* Visualize the data (Temp Avg) !!!! ;
proc sgplot data=weather;
	series x=date y=TAVG;
run;
quit;

* Visualize the data (Temp Max) !!!! ;
proc sgplot data=weather;
	series x=date y=TMAX;
run;
quit;

* Visualize the data (Temp Min) !!!! ;
proc sgplot data=weather;
	series x=date y=TMIN;
run;
quit;

* Visualize the data (FASTEST 2 MIN WIND SPEED) !!!! ;
proc sgplot data=weather;
	series x=date y=WSF2;
run;
quit;

* Visualize the data (FASTEST 5 SEC WIND SPEED) !!!! ;
proc sgplot data=weather;
	series x=date y=WSF5;
run;
quit;

* Visualize the data (CO) !!!! ;
proc sgplot data=CO;
	series x=date y='Daily Max 8-hour CO Concentratio'n;
run;
quit;

* Visualize the data (NO) !!!! ;
proc sgplot data=NO;
	series x=date y='Daily Max 1-hour NO2 Concentrati'n;
run;
quit;


* Visualize the data (SO2) !!!! ;
proc sgplot data=SO2;
	series x=date y='Daily Max 1-hour SO2 Concentrati'n;
run;
quit;



/*Creating Training Data Sets*/
data train_ozone;
	set work.ozone_raleigh2;
	if Date=. then delete;
	else if Date>= '19Apr2020'd then 'Daily Max 8-hour Ozone Concentra'n=.;
	keep date 'Daily Max 8-hour Ozone Concentra'n;
run;

data train_CO;
	set work.CO;
	if Date=. then delete;
	else if Date>='19Apr2020'd then 'Daily Max 8-hour CO Concentratio'n=.;
	keep date 'Daily Max 8-hour CO Concentratio'n;
run;

data train_NO;
	set work.NO;
	if Date=. then delete;
	else if Date>='19Apr2020'd then 'Daily Max 1-hour NO2 Concentrati'n=.;
	keep date 'Daily Max 1-hour NO2 Concentrati'n;
run;

data train_SO2;
	set work.SO2;
	if Date=. then delete;
	else if Date>='19Apr2020'd then 'Daily Max 1-hour SO2 Concentrati'n=.;
	keep date 'Daily Max 1-hour SO2 Concentrati'n;
run;

data train_weather;
	set work.weather;
	if Date=. then delete;
	else if Date>='19Apr2020'd then do;
	PRCP=.;
	SNOW=.;
	SNWD=.;
	TAVG=.;
	TMAX=.;
	TMIN=.;
	WSF2=.;
	WSF5=.;
	AWND=.;

end;
	keep date PRCP	SNOW	SNWD	TAVG	TMAX	TMIN	WSF2	WSF5 AWND;
run;


/*Creating a joint dataset with all variables*/
data joined_ozone;
	merge work.train_ozone work.train_CO work.train_NO work.train_SO2 work.train_weather;
	by date;
run;

/*Running a Regression to see what is sig*/
proc glmselect data=joined_ozone;
model 'Daily Max 8-hour Ozone Concentra'n = 'Daily Max 8-hour CO Concentratio'n 'Daily Max 1-hour NO2 Concentrati'n 'Daily Max 1-hour SO2 Concentrati'n  PRCP	SNOW	SNWD	
	TMAX		WSF2	WSF5 AWND / selection=forward select=AIC details=steps;

run;
quit;

proc glmselect data=joined_ozone;
model 'Daily Max 8-hour Ozone Concentra'n = 'Daily Max 8-hour CO Concentratio'n 'Daily Max 1-hour NO2 Concentrati'n 'Daily Max 1-hour SO2 Concentrati'n  PRCP	SNOW	SNWD	
	TMIN		WSF2	WSF5 AWND / selection=forward select=AIC details=steps;

run;
quit;

proc glmselect data=joined_ozone;
model 'Daily Max 8-hour Ozone Concentra'n = 'Daily Max 8-hour CO Concentratio'n 'Daily Max 1-hour NO2 Concentrati'n 'Daily Max 1-hour SO2 Concentrati'n  PRCP	SNOW	SNWD	
	TAVG		WSF2	WSF5 AWND / selection=forward select=AIC details=steps;

run;
quit;

/*MODELS TO TRY ARE TMAX, CO,NO AND POSSIBLY SO*/
/*CHECKING RESIDUALS OF MODEL WITH TMAX, NO, CO,SO*/
proc reg data=joined_ozone;
model 'Daily Max 8-hour Ozone Concentra'n = 'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour SO2 Concentrati'n  'Daily Max 1-hour NO2 Concentrati'n 
	TMAX		;
output out=residreg1 r=resid;

run;
quit;

proc sgplot data=train_ozone;
	series x=date y='Daily Max 8-hour Ozone Concentra'n ;
run;
proc sgplot data=residreg1;
	series x=date y=resid;
run;
quit;

/*CHECKING RESIDUALS OF MODEL WITH TMAX, NO, CO*/
proc reg data=joined_ozone;
model 'Daily Max 8-hour Ozone Concentra'n = 'Daily Max 8-hour CO Concentratio'n   'Daily Max 1-hour NO2 Concentrati'n 
	TMAX		;
output out=residreg2 r=resid;

run;
quit;

proc sgplot data=train_ozone;
	series x=date y='Daily Max 8-hour Ozone Concentra'n ;
run;
proc sgplot data=residreg1;
	series x=date y=resid;
run;
quit;

proc sgplot data=residreg2;
	series x=date y=resid;
run;
quit;

/*CHOOSING THE MODEL WITH ONLY TMAX, CO, NO2*/
/*RUNNING A PROC ARIMA*/
proc arima data=JOINED_OZONE plots=all;
identify var='Daily Max 8-hour Ozone Concentra'n  NLAG= 1095 crosscorr=( 'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX  );
	estimate input=('Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX	 ) method=ML;
	forecast lead=0 out=seasonal_resid1;
run;
quit;

proc arima data=seasonal_resid1 ;
identify var=residual NLAG= 1095 stationarity=(adf=2);
run;
quit;

/*STILL APPEARS TO HAVE A SEASONAL DIFFERENCE TRYING Sin Cos */
data ozone_sc;
	set work.joined_ozone;
	pi=constant("pi");
	s1=sin(2*pi*1*_n_/365);
	c1=cos(2*pi*1*_n_/365);
	s2=sin(2*pi*2*_n_/365);
	c2=cos(2*pi*2*_n_/365);
	s3=sin(2*pi*3*_n_/365);
	c3=cos(2*pi*3*_n_/365);
	s4=sin(2*pi*4*_n_/365);
	c4=cos(2*pi*4*_n_/365);
	s5=sin(2*pi*5*_n_/365);
	c5=cos(2*pi*5*_n_/365);
	s6=sin(2*pi*6*_n_/365);
	c6=cos(2*pi*6*_n_/365);
	s7=sin(2*pi*7*_n_/365);
	c7=cos(2*pi*7*_n_/365);
	s8=sin(2*pi*8*_n_/365);
	c8=cos(2*pi*8*_n_/365);
	s9=sin(2*pi*9*_n_/365);
	c9=cos(2*pi*9*_n_/365);
	s10=sin(2*pi*10*_n_/365);
	c10=cos(2*pi*10*_n_/365);
	s11=sin(2*pi*11*_n_/365);
	c11=cos(2*pi*11*_n_/365);
	s12=sin(2*pi*12*_n_/365);
	c12=cos(2*pi*12*_n_/365);
	s13=sin(2*pi*13*_n_/365);
	c13=cos(2*pi*13*_n_/365);
	s14=sin(2*pi*14*_n_/365);
	c14=cos(2*pi*14*_n_/365);
	s15=sin(2*pi*15*_n_/365);
	c15=cos(2*pi*15*_n_/365);
	s16=sin(2*pi*16*_n_/365);
	c16=cos(2*pi*16*_n_/365);
	s17=sin(2*pi*17*_n_/365);
	c17=cos(2*pi*17*_n_/365);
	s18=sin(2*pi*18*_n_/365);
	c18=cos(2*pi*18*_n_/365);
	s19=sin(2*pi*19*_n_/365);
	c19=cos(2*pi*19*_n_/365);
	s20=sin(2*pi*20*_n_/365);
	c20=cos(2*pi*20*_n_/365);

	
run;

/*Testing different combination to find the best model*/
proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(  'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX );
	estimate input=( 'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX ) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;


proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(  'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6);
	estimate input=( 'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;


proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(  'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6);
	estimate p =(1,365) q=(365) input=( 'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;

proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=365 crosscorr=(  'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6);
	estimate p =(1,60,365) q=(365) input=( 'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;

proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(  'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6);
	estimate p =(1,5,7,60,90,365) q=(365) input=( 'Daily Max 8-hour CO Concentratio'n  'Daily Max 1-hour NO2 Concentrati'n   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;

proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(     TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6);
	estimate p =(1,5,7,60,90,365) q=(365) input=(    TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;
/*Final Model ar terms 1,5,7,60,90,365, ma terms 365*****************/
/*********************************************************************/
/***********************************************************************/
/***********************************************************************/
/********************************************************************/
/*********************************************************************/
/***********************************************************************/
/***********************************************************************/
/********************************************************************/
/************************************/

/*Creating a Data set to use for forecasting */
data ozone_train ozone_validation ozone_test;
	set work.ozone_raleigh2;
	if Date=. then delete;
	else if Date<='19APR2020'd then output ozone_train;
	else if Date<='17MAY2020'd then output ozone_validation;
	else output ozone_test;
run;

data tr_v_tmax;
	set work.weather;
	if Date=. then delete;
	else if Date>='17MAY2020'd then 
	TMAX=.;
	

	keep date	TMAX	;
run;

data forecast1;
	merge work.train_ozone work.tr_v_tmax;
	by date;
run;

data forecast2;
	set work.forecast1;
	pi=constant("pi");
	s1=sin(2*pi*1*_n_/365);
	c1=cos(2*pi*1*_n_/365);
	s2=sin(2*pi*2*_n_/365);
	c2=cos(2*pi*2*_n_/365);
	s3=sin(2*pi*3*_n_/365);
	c3=cos(2*pi*3*_n_/365);
	s4=sin(2*pi*4*_n_/365);
	c4=cos(2*pi*4*_n_/365);
	s5=sin(2*pi*5*_n_/365);
	c5=cos(2*pi*5*_n_/365);
	s6=sin(2*pi*6*_n_/365);
	c6=cos(2*pi*6*_n_/365);
	s7=sin(2*pi*7*_n_/365);
	c7=cos(2*pi*7*_n_/365);
	s8=sin(2*pi*8*_n_/365);
	c8=cos(2*pi*8*_n_/365);
	s9=sin(2*pi*9*_n_/365);
	c9=cos(2*pi*9*_n_/365);
	s10=sin(2*pi*10*_n_/365);
	c10=cos(2*pi*10*_n_/365);


	
run;

proc arima data=forecast2 plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(     TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6);
	estimate p =(1,5,7,60,90,365) q=(365) input=(    TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6) method=ML;
	forecast lead=28 out=model1;
run;
quit;

*Calculate MAPE;
data model1;
	set model1;
	where 'Daily Max 8-hour Ozone Concentra'n=. ;
	keep forecast;
run;

data check_resid_1;
	set model1;
	set ozone_validation;
	resid = 'Daily Max 8-hour Ozone Concentra'n  - forecast;
run;

proc sql;
select mean(abs(resid)/'Daily Max 8-hour Ozone Concentra'n)
from check_resid_1;
quit;
/*MAPE is 35%*/
proc sgplot data=check_resid_1;
	series x=Date y='Daily Max 8-hour Ozone Concentra'n;
	series x=Date y=Forecast;
	xaxis label='Date (Monthly)';
	yaxis label='Ozone Concentration (ppm)';
	title 'Average Daily 8 Hr Maximum Ozone Concentration'; 
run;

/*Trying a new model with different combinations of AR and MA */
proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(     TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6 s7 c7 s8 c8 s9 c9 s10 c10 s11 c11 s12 c12 s13 c13 s14 c14 s15 c15 s16 c16 s17 c17 s18 c18 s19 c19 s20 c20);
	estimate input=(   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6 s7 c7 s8 c8 s9 c9 s10 c10 s11 c11 s12 c12 s13 c13 s14 c14 s15 c15 s16 c16 s17 c17 s18 c18 s19 c19 s20 c20) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;

proc arima data=ozone_sc plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(     TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6 s7 c7 s8 c8 s9 c9 s10 c10 s11 c11 s12 c12 s13 c13 s14 c14 s15 c15 s16 c16 s17 c17 s18 c18 s19 c19 s20 c20);
	estimate p=(1) q=1 input=(   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6 s7 c7 s8 c8 s9 c9 s10 c10 s11 c11 s12 c12 s13 c13 s14 c14 s15 c15 s16 c16 s17 c17 s18 c18 s19 c19 s20 c20) method=ML;
	forecast lead=0 out=CO_resid;
run;
quit;

/*Creating new splits*/
data ozone_train ozone_validation ozone_test;
	set work.ozone_raleigh2;
	if Date=. then delete;
	else if Date<='19APR2020'd then output ozone_train;
	else if Date<='17MAY2020'd then output ozone_validation;
	else output ozone_test;
run;
/*Creating new data set with just temperature max*/
data tr_v_tmax;
	set work.weather;
	if Date=. then delete;
	else if Date>='17MAY2020'd then 
	TMAX=.;
	
	keep date	TMAX	;
run;
/*Merging data sets*/
data forecast1;
	merge work.train_ozone work.tr_v_tmax;
	by date;
run;
/*Creating sins and cos*/
data forecast3;
	set work.forecast1;
	pi=constant("pi");
	s1=sin(2*pi*1*_n_/365);
	c1=cos(2*pi*1*_n_/365);
	s2=sin(2*pi*2*_n_/365);
	c2=cos(2*pi*2*_n_/365);
	s3=sin(2*pi*3*_n_/365);
	c3=cos(2*pi*3*_n_/365);
	s4=sin(2*pi*4*_n_/365);
	c4=cos(2*pi*4*_n_/365);
	s5=sin(2*pi*5*_n_/365);
	c5=cos(2*pi*5*_n_/365);
	s6=sin(2*pi*6*_n_/365);
	c6=cos(2*pi*6*_n_/365);
	s7=sin(2*pi*7*_n_/365);
	c7=cos(2*pi*7*_n_/365);
	s8=sin(2*pi*8*_n_/365);
	c8=cos(2*pi*8*_n_/365);
	s9=sin(2*pi*9*_n_/365);
	c9=cos(2*pi*9*_n_/365);
	s10=sin(2*pi*10*_n_/365);
	c10=cos(2*pi*10*_n_/365);
	s11=sin(2*pi*11*_n_/365);
	c11=cos(2*pi*11*_n_/365);
	s12=sin(2*pi*12*_n_/365);
	c12=cos(2*pi*12*_n_/365);
	s13=sin(2*pi*13*_n_/365);
	c13=cos(2*pi*13*_n_/365);
	s14=sin(2*pi*14*_n_/365);
	c14=cos(2*pi*14*_n_/365);
	s15=sin(2*pi*15*_n_/365);
	c15=cos(2*pi*15*_n_/365);
	s16=sin(2*pi*16*_n_/365);
	c16=cos(2*pi*16*_n_/365);
	s17=sin(2*pi*17*_n_/365);
	c17=cos(2*pi*17*_n_/365);
	s18=sin(2*pi*18*_n_/365);
	c18=cos(2*pi*18*_n_/365);
	s19=sin(2*pi*19*_n_/365);
	c19=cos(2*pi*19*_n_/365);
	s20=sin(2*pi*20*_n_/365);
	c20=cos(2*pi*20*_n_/365);
	
run;
/*Running and ARIMAX*/
proc arima data=forecast3 plots=all;
identify var= 'Daily Max 8-hour Ozone Concentra'n nlag=1095 crosscorr=(     TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6 s7 c7 s8 c8 s9 c9 s10 c10 s11 c11 s12 c12 s13 c13 s14 c14 s15 c15 s16 c16 s17 c17 s18 c18 s19 c19 s20 c20);
	estimate p=(1) q=1 input=(   TMAX s1 c1 s2 c2 s3 c3 s4 c4 s5 c5 s6 c6 s7 c7 s8 c8 s9 c9 s10 c10 s11 c11 s12 c12 s13 c13 s14 c14 s15 c15 s16 c16 s17 c17 s18 c18 s19 c19 s20 c20) method=ML;
	forecast lead=28 out=model2;
run;
quit;

*Calculate MAPE;
data model2;
	set model2;
	where 'Daily Max 8-hour Ozone Concentra'n=. ;
	keep forecast;
run;

data check_resid_2;
	set model2;
	set ozone_validation;
	resid = 'Daily Max 8-hour Ozone Concentra'n  - forecast;
run;

proc sql;
select mean(abs(resid)/'Daily Max 8-hour Ozone Concentra'n)
from check_resid_2;
quit;