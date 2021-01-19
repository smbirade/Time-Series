/* Roll Up Data Into Monthly Data-set */
proc sql;
	create table ts1.ozone_monthly as
	select month(Date) as month, year(Date) as year, mean(Daily_Max_8_hour_ozone_concentra) as monthly_avg_ozone
		from ts1.ozone_raleigh2
		group by year, month;
run;

data ts1.ozone_monthly;
	set ts1.ozone_monthly;
	Date = mdy(month, 1, year);
	format Date monyy.;
	timestep = _n_;
run;

/* Split into Training, Testing, and Validation Data */
data ts1.otrain ts1.ovalid ts1.otest;
	set ts1.ozone_monthly;
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

/* Check Unaltered Data with Augmented Dickey-Fuller */
proc arima data=ts1.otrain plots=all;
	identify var=monthly_avg_ozone nlag=10 stationarity=(adf=2);
run;
* Use Single Mean, mean is +5 sigma;
* Single Mean, Zero Lag fails to reject null, data non-stationary;

/* Try First Differencing */
proc arima data=ts1.ozone_monthly plots=all;
	identify var=monthly_avg_ozone(1) nlag=10 stationarity=(adf=2);
run;
* Stationarity Achieved by First Differencing;

/* Try Trend */
proc arima data=ts1.ozone_monthly plots=all;
	identify var=monthly_avg_ozone nlag=10 stationarity=(adf=2) crosscorr=timestep;
	estimate input=timestep;
run;
* Stationarity Achieved by Removing Linear Trend;

/* Test for White Noise in Differenced Data */
proc arima data=ts1.ozone_monthly plot(unpack)=all;
	identify var=monthly_avg_ozone(1) nlag=24 stationarity=(adf=2);
	estimate method=ML;
run; quit;
