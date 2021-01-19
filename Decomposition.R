#Installing Packages needed
install.packages('tseries')
install.packages('forecast',dependencies = T)
install.packages(c('expsmooth','lmtest','zoo','seasonal','haven','fma'))
library(tseries)
library(forecast)
library(haven)
library(fma)
library(expsmooth)
library(lmtest)
library(zoo)
library(seasonal)
library(lubridate)
library(dplyr)

#Reading in the File 

ozone2= read.csv(file='Ozone_Raleigh2.csv')
#Creating Month and Year Varibales 
ozone2$Year = format(as.Date(ozone2$Date,format ='%m/%d/%Y' ), '%Y')

ozone2$Month = format(as.Date(ozone2$Date,format ='%m/%d/%Y' ), '%m')

#Number of missing per year 
year_obs=tapply(ozone2$Date, INDEX =ozone2$Year, FUN = length )

days_in_years=c(365,365,366,365,365,365,0)
total_missing = days_in_years-year_obs
total_missing
sum(total_missing)+152

#Jan 2017 Mean Max daily ozone concentration 
ozone_month = tapply(ozone2$Daily.Max.8.hour.Ozone.Concentration, INDEX =list(ozone2$Month, ozone2$Year), FUN = mean )
ozone_month

#Grouping Data Monthly and Time plot 

ozone_grouped= ozone2 %>% group_by(Year, Month) %>% summarise(mean_conc=mean(Daily.Max.8.hour.Ozone.Concentration))

ozone_ts= ts(ozone_grouped$mean_conc, start=2014, frequency=12)

plot(ozone_ts, xlab='Month',ylab='Max 8 Hour Ozone Concentration', main='Time Plot of Mean Monthly Max 8 Hour Ozone Concentration ')

#Decomposing Data 

decomp_stl <- stl(ozone_ts, s.window = 7)
plot(decomp_stl)

decomp_classical=decompose(ozone_ts)
plot(decomp_classical)
decomp_stl$time.series[,2]
#There appears to be changes to the seasonal compenont so STL will be used to allow for changing trends and seasons
#Overlaid with trend 
plot(ozone_ts, col = "grey", main = "Trend/Cycle", xlab = "", ylab = "T", lwd = 2)
lines(decomp_stl$time.series[,2], col = "red", lwd = 2)

#Overlaid with season
season=ozone_ts-decomp_stl$time.series[,1]
plot(ozone_ts, col = "grey", main = "Seasonally Adjusted", xlab = "", ylab = "N", lwd = 2)
lines(season, col = "red", lwd = 2)

# Plot seasonal subseries by months
monthplot(decomp_stl$time.series[,"seasonal"], main = "Monthly Effects", ylab = "Seasonal Sub Series", xlab = "Seasons (Months)", lwd = 2)

