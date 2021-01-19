libname ts1 "/opt/sas/home/smbirade/sasuser.viya/";
proc import datafile = '/opt/sas/home/smbirade/sasuser.viya/Ozone_Raleigh2.csv'
 out = work.ozone_raleigh2
 dbms = CSV
 ;
run;
/* Roll Up Data Into Monthly Data-set */
options validvarname=any;
proc sql;
	create table ts1.ozone_monthly as
	select month(Date) as month, year(Date) as year, mean('Daily Max 8-hour Ozone Concentra'n) as monthly_avg_ozone
		from work.ozone_raleigh2
		group by year, month;
run;

data ts1.ozone_monthly;
	set ts1.ozone_monthly;
	Date = mdy(month, 1, year);
	format Date monyy.;
	timestep = _n_;
run;
/*Creating a Dummy Vairable for Season*/
data ts1.ozone_monthly2;
	set ts1.ozone_monthly;
	if month=1 then seas1=1; else seas1=0;
	if month=2 then seas2=1; else seas2=0;
	if month=3 then seas3=1; else seas3=0;
	if month=4 then seas4=1; else seas4=0;
	if month=5 then seas5=1; else seas5=0;
	if month=6 then seas6=1; else seas6=0;
	if month=7 then seas7=1; else seas7=0;
	if month=8 then seas8=1; else seas8=0;
	if month=9 then seas9=1; else seas9=0;
	if month=10 then seas10=1; else seas10=0;
	if month=11 then seas11=1; else seas11=0;
run;
/* Split into Training, Testing, and Validation Data */
data ts1.otrain ts1.ovalid ts1.otest;
	set ts1.ozone_monthly2;
	if Date=. then delete;
	else if Date<'01jan2019'd then output ts1.otrain;
	else if Date<'01jan2020'd then output ts1.ovalid;
	else output ts1.otest;
run;

/* Visualize Monthly Data */
proc sgplot data=ts1.otrain;
	series x=Date y=monthly_avg_ozone;
	xaxis label='Date (Monthly)';
	yaxis label='Ozone Concentration (ppm)';
	title 'Average Daily 8 Hr Maximum Ozone Concentration'; 
run;

/*Testing to see if seasonality is a random walk or not*/
proc arima data=ts1.otrain;
identify var=monthly_avg_ozone stationarity=(adf=2 dlag=12);
run;
quit;
/*Reject Ho seasonality is not a random walk, use a dummy vairable*/

*Testing if after seasonality is "removed" if data is stationary;
proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  stationarity=(adf=2);
	estimate input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;
	forecast out=dummy_out lead=0;
run;
quit;
*Reject Ho data is stationairy;

proc arima data=dummy_out;
identify var=residual stationarity=(adf=2);
run;
quit;

* Fit an ARIMA model with seasonal dummy vairables and diffrences  ; 
proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate  input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;

proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;

proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(12) p=(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;

proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(12) p=(1,12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;

proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(1,12) p=(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;

proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(12) p=(12,24) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;

proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(12,24) p=(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;
/*Best Additive Model seasonal AR and MA*/
proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(12) p=(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;


/*Trying Multiplicative Models */

proc arima data=ts1.otrain;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(1)(12) p=(1)(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;

run;
quit;


data ozone_monthly_train;
	set ts1.ozone_monthly2; *change for name of data set;
	if date>'31dec2018'd then monthly_avg_ozone=.; *change for whatever your ozone variable is;
run;
/*Testing our model on validation*/

proc arima data=ozone_monthly_train;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(1)(12) p=(1)(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;
	
	
	forecast lead=12;
run;
quit;


proc arima data=ozone_monthly_train;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate q=(12) p=(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;
	
	
	forecast lead=12;
run;
quit;

/*Testing our model on test*/
proc arima data=ts1.ozone_monthly2;
	identify var=monthly_avg_ozone nlag=36 crosscorr=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11)  ;
	estimate p=(1)(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;
	estimate p=(2)(12) input=(seas1 seas2 seas3 seas4 seas5 seas6 seas7 seas8 seas9 seas10 seas11) method=ML;
	
	forecast back=5 lead=5;
run;
quit;





