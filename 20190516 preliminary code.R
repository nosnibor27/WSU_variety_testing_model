library(stringr)
library(RNetCDF)
library(zoo)
library(rethinking)

#loading in dataframe (df)
df = read.csv(file = "WSU_variety_testing_2015_2018.csv", stringsAsFactors = FALSE)

N <- nrow(df)

#capitalizing town names
df$City <- str_to_title(df$City)

#making labels for each unique location year to query
df$unique <- paste0(df$City,"_",df$Season,"_",df$Year)

matrix(c(unique(df$unique),rep(NA,9)),25,4)
#converting coordinates
df$lon_1 <- str_replace(df$Longitude,"W","")
df$lat_1 <- str_replace(df$Latitude,"N","")
#separating by word
df$lon_2 <- as.numeric(word(df$lon_1,1))
df$lon_3 <- as.numeric(word(df$lon_1,2))
df$lat_2 <- as.numeric(word(df$lat_1,1))
df$lat_3 <- as.numeric(word(df$lat_1,2))
#converting to decimal degrees
df$lon <- -(df$lon_2+(df$lon_3/60))
df$lat <- df$lat_2+(df$lat_3/60)
#heading date column
df$hd_1 <- as.character(as.Date(as.character(df$Head_Date),"%j"))
#removing the year
df$hd_2 <- str_remove(df$hd_1,"2019")
#creating a date lookup
df$hd <- as.Date(paste0(df$Year,df$hd_2))
#date lookup for planting date
df$pd <- as.Date(df$Planting_Date,"%m/%d/%Y")
#preparing gdd columns
df$precip <- rep(NA,N)
df$evap <- rep(NA,N)
df$gdd <- rep(NA,N)
df$gdd_rdr <- rep(NA,N)

#base url
url_2 <- "http://thredds.northwestknowledge.net:8080/thredds/dodsC/MET/"

#year list to query
year_list <- c("2014.nc",
               "2015.nc",
               "2016.nc",
               "2017.nc",
               "2018.nc")

#variable list
variable_1 <- c("tmmx/tmmx_","tmmn/tmmn_","pr/pr_","pet/pet_")

#list of days for the count argument
day_list <- c(365,365,366,365,365)

#function to calculate growing degree-days (GDD) with a base temp of 0 C
GDD <- function(max_temp,min_temp){
  ifelse((((max_temp-273.15)+(min_temp-273.15))/2)<0,0,
         (((max_temp-273.15)+(min_temp-273.15))/2))
}

#sorting by unique coordinates
unique_matrix <- matrix(NA,91,30)
unique_matrix[,1] <- as.numeric(as.vector(sapply(split(df$lon,df$unique),max)))
unique_matrix[,2] <- as.numeric(as.vector(sapply(split(df$lat,df$unique),max)))
unique_matrix[,3] <- sort(unique(df$unique))
#add other variables here, increase columns

#collecting data by row from unique matrix
for (n in 1:nrow(unique_matrix)){
  #starting a matrix for GDD values
  wr <- matrix(NA,1826,5)
  #collecting maximum and minimum temperatures for all years in range
  for (i in 1:4){
    nc_1 <- open.nc(paste0(url_2, variable_1[i],year_list[1]))
    #assinging lon and lat from df
    x <- as.numeric(unique_matrix[n,1])
    y <- as.numeric(unique_matrix[n,2])
    #getting lon and lat from file
    lat <- var.get.nc(nc_1,"lat")
    lon <- var.get.nc(nc_1,"lon")
    #finding index values
    flat = match(abs(lat - y) < 1/48, 1)
    latindex = which(flat %in% 1)
    flon = match(abs(lon - x) < 1/48, 1)
    lonindex = which(flon %in% 1)
    #getting the first variable
    var_1 <- as.numeric(var.get.nc(nc_1, variable = 4, start = c(lonindex, latindex, 1), count=c(1,1,day_list[1])))
    #repeating for other years in range
    nc_2 <- open.nc(paste0(url_2, variable_1[i],year_list[2]))
    var_2 <- as.numeric(var.get.nc(nc_2, variable = 4, start = c(lonindex, latindex, 1), count=c(1,1,day_list[2])))
    nc_3 <- open.nc(paste0(url_2, variable_1[i],year_list[3]))
    var_3 <- as.numeric(var.get.nc(nc_3, variable = 4, start = c(lonindex, latindex, 1), count=c(1,1,day_list[3])))
    nc_4 <- open.nc(paste0(url_2, variable_1[i],year_list[4]))
    var_4 <- as.numeric(var.get.nc(nc_4, variable = 4, start = c(lonindex, latindex, 1), count=c(1,1,day_list[4])))
    nc_5 <- open.nc(paste0(url_2, variable_1[i],year_list[5]))
    var_5 <- as.numeric(var.get.nc(nc_5, variable = 4, start = c(lonindex, latindex, 1), count=c(1,1,day_list[5])))
    #compiling together
    var <- c(var_1,var_2,var_3,var_4,var_5)
    #saving to matrix
    wr[,i] <- var
  }
  #calculating GDD
  wr[,5] <- GDD(wr[,1],wr[,2])
  assign(paste0(unique_matrix[n,3],"_wr"),wr)
  #printing progress
  print(n)
}

#date lookups
ref_date <- as.Date(seq(41638,43463,1),origin="1900-01-01")
ref_zoo = read.zoo(as.data.frame(ref_date),format = "%Y-%m-%d")
ref_index = index(ref_zoo)
ref_doy <- as.integer(format(ref_date,"%j"))

#function to calculate photoperiod (PP) which includes civil twilight
PP <- function(J,x,y){
  #solar declination
  solar_dec <- 0.409*sin(((2*pi/365)*J)-1.39)
  #converting to radians
  long <- (pi/180)*x
  lat <- (pi/180)*y
  #sunset time
  sunset <- (24/(2*pi))*((-long)-acos(((sin(lat)*sin(solar_dec))-sin(-0.10472))
                                      /(cos(lat)*cos(solar_dec))))
  #sunrise time
  sunrise <- (24/(2*pi))*((-long)+acos(((sin(lat)*sin(solar_dec))-sin(-0.10472))
                                       /(cos(lat)*cos(solar_dec))))
  #need to add 24 to sunset because negative
  #need to convert from UTC
  #quick and dirty timezone calculation from longitude using 360/24
  ((sunset-round(x/15))+24)-(sunrise-round(x/15))
}

#function for relative development rate (RDR)
RDR <- function(c,p){
  1-c*(20-p)^2
}

for(n in 1:N){
  A <- get(paste0(df$City[n],"_",df$Season[n],"_",df$Year[n],"_wr"))
  #planting and heading dates
  dates <- c(df$pd[n],df$hd[n])
  #starting what will be lookup vecotr
  lookup <- 0
  #adding index locations
  for (d in dates){
    pointer = which.min(abs(as.Date(d) - ref_index))
    lookup <- append(lookup,pointer,after=length(lookup))
  }
  #removing initial 0
  lookup <- lookup[-1]
  #calculating sum and adding to dataframe
  df$precip[n] <- sum(A[(lookup[1]:lookup[2]),3])
  df$evap[n] <- sum(A[(lookup[1]:lookup[2]),4])
  df$gdd[n] <- sum(A[(lookup[1]:lookup[2]),5])
  #gdd vector
  daily_gdd <- A[(lookup[1]:lookup[2]),5]
  daily_pp <- PP(ref_doy[lookup[1]:lookup[2]],df$lon[n],df$lat[n])
  daily_rdr <- RDR(0.004,daily_pp)
  #calculating
  gdd_rdr <- daily_gdd*daily_rdr
  #adding to dataframe
  df$gdd_rdr[n] <- sum(gdd_rdr)
  #printing progress
  print(n)
}

#standardizing
df$gdd_s <- (df$gdd-mean(df$gdd))/sd(df$gdd)

#adding averages
unique_matrix[,4] <- as.vector(sapply(split(df$gdd,df$unique),mean))
unique_matrix[,5] <- as.vector(sapply(split(df$gdd,df$unique),sd))
unique_matrix[,6] <- as.vector(sapply(split(df$gdd_rdr,df$unique),mean))
unique_matrix[,7] <- as.vector(sapply(split(df$gdd_rdr,df$unique),sd))
unique_matrix[,8] <- as.vector(sapply(split(df$precip,df$unique),mean))
unique_matrix[,9] <- as.vector(sapply(split(df$precip,df$unique),sd))

#standardizing
df$gdd_s <- (df$gdd-mean(df$gdd))/sd(df$gdd)
df$gdd_rdr_s <- (df$gdd_rdr-mean(df$gdd_rdr))/sd(df$gdd_rdr)

#adding city factors to data frame and matrix
df$City_f <- as.numeric(factor(df$City))
df$Year_f <- as.numeric(factor(df$Year))
df$Season_f <- as.numeric(factor(df$Season))

unique_matrix[,10] <- as.vector(sapply(split(df$City_f,df$unique),mean))
unique_matrix[,11] <- as.vector(sapply(split(df$Year_f,df$unique),mean))
unique_matrix[,12] <- as.vector(sapply(split(df$Season_f,df$unique),mean))

test_model_1 <-  map2stan(
  alist(
    gdd ~ dnorm(mu,sigma),
    mu <- a + a_season[season] + a_town[town] + a_year[year],
    a_season[season] ~ dnorm(0,sigma_season),
    a_town[town] ~ dnorm(0,sigma_town),
    a_year[year] ~ dnorm(0,sigma_year),
    a ~ dnorm(0,1),
    sigma_town ~ dexp(1),
    sigma_season ~ dexp(1),
    sigma_year ~ dexp(1),
    sigma <- dexp(1)
  ) ,
  data=list(gdd = df$gdd_s,
            town = df$City_f,
            year = df$Year_f,
            season = df$Season_f),
  warmup=500,
  iter=1500,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.95,max_treedepth=14),
  verbose = TRUE
) 
plot(test_model_1)
precis(test_model_1,depth=2)

test_model_3 <-  map2stan(
  alist(
    gdd_est ~ dnorm(mu,sigma),
    mu <- a + a_season[season] + a_town[town] + a_year[year],
    gdd_est ~ dnorm(gdd_obs,gdd_sd),
    a_season[season] ~ dnorm(0,sigma_season),
    a_town[town] ~ dnorm(0,sigma_town),
    a_year[year] ~ dnorm(0,sigma_year),
    a ~ dnorm(1500,300),
    sigma_town ~ dexp(0.01),
    sigma_season ~ dexp(0.01),
    sigma_year ~ dexp(0.01),
    sigma <- dexp(0.01)
  ) ,
  data = list(gdd_obs = as.numeric(unique_matrix[,4]),
              gdd_sd = as.numeric(unique_matrix[,5]),
               town = as.numeric(unique_matrix[,10]),
               year = as.numeric(unique_matrix[,11]),
               season = as.numeric(unique_matrix[,12])),
  start=list(gdd_est=as.numeric(unique_matrix[,4])),
  WAIC=FALSE,
  warmup=500,
  iter=1500,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.95,max_treedepth=14),
  verbose = TRUE
) 
plot(test_model_1)
precis(test_model_3,depth=2)






test_model_1 <-  map2stan(
  alist(
    gdd ~ dnorm(mu,sigma),
    mu <- a + a_season[season] + a_town[town] + a_year[year],
    a_season[season] ~ dnorm(0,sigma_season),
    a_town[town] ~ dnorm(0,sigma_town),
    a_year[year] ~ dnorm(0,sigma_year),
    a ~ dnorm(1500,500),
    sigma_town ~ dexp(0.001),
    sigma_season ~ dexp(0.001),
    sigma_year ~ dexp(0.001),
    sigma <- dexp(0.001)
  ) ,
  data=list(gdd = df$gdd,
            town = df$City_f,
            year = df$Year_f,
            season = df$Season_f),
  warmup=500,
  iter=1500,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.95,max_treedepth=14),
  verbose = TRUE
)

precis(test_model_2,depth=2)

test_model_2 <-  map2stan(
  alist(
    gdd ~ dnorm(mu,sigma),
    mu <- a + a_season[season] + a_town[town] + a_year[year],
    a_season[season] ~ dnorm(0,sigma_season),
    a_town[town] ~ dnorm(0,sigma_town),
    a_year[year] ~ dnorm(0,sigma_year),
    a ~ dnorm(1500,500),
    sigma_town ~ dexp(0.001),
    sigma_season ~ dexp(0.001),
    sigma_year ~ dexp(0.001),
    sigma <- dexp(0.001)
  ) ,
  data=list(gdd = as.numeric(unique_matrix[,4]),
            town = as.numeric(unique_matrix[,10]),
            year = as.numeric(unique_matrix[,11]),
            season = as.numeric(unique_matrix[,12])),
  warmup=500,
  iter=1500,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.95,max_treedepth=14),
  verbose = TRUE
)

test_model_3 <-  map2stan(
  alist(
    gdd_est ~ dnorm(mu,sigma),
    mu <- a + a_season[season] + a_town[town] + a_year[year],
    gdd_est ~ dnorm(gdd_obs,gdd_sd),
    a_season[season] ~ dnorm(0,sigma_season),
    a_town[town] ~ dnorm(0,sigma_town),
    a_year[year] ~ dnorm(0,sigma_year),
    a ~ dnorm(1500,300),
    sigma_town ~ dexp(0.01),
    sigma_season ~ dexp(0.01),
    sigma_year ~ dexp(0.01),
    sigma <- dexp(0.01)
  ) ,
  data = list(gdd_obs = as.numeric(unique_matrix[,4]),
              gdd_sd = as.numeric(unique_matrix[,5]),
              town = as.numeric(unique_matrix[,10]),
              year = as.numeric(unique_matrix[,11]),
              season = as.numeric(unique_matrix[,12])),
  start=list(gdd_est=as.numeric(unique_matrix[,4])),
  WAIC=FALSE,
  warmup=500,
  iter=1500,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.95,max_treedepth=14),
  verbose = TRUE
) 















post_1 <- extract.samples(test_model_1,n=5000)

gdd <- ((post$a+post$a_season[,2]+post$a_town[,3])
        *sd(df$gdd)+mean(df$gdd))
c(mean(gdd),sd(gdd))

town_summary <- as.data.frame(matrix(0,max(df$City_f),1))
town_summary$town <- sort(unique(df$City))
town_summary$post_mu <- apply(post$a_town,2,mean)
town_summary$post_sd <- apply(post$a_town,2,sd)
town_summary$gdd_mu <- town_summary$post_mu*sd(df$gdd)
town_summary$gdd_sd <- town_summary$post_sd*sd(df$gdd)

sd(df$gdd)

saveRDS(post_1,file="post_1.rdata")

posterior <- post_1

phy <- rep(NA,24)
for (n in 1:24){
  test <- posterior$a + posterior$a_season[,2] + posterior$a_town[,n]
  
  test_2 <- (test*(sd(df$gdd)))+mean(df$gdd)
  
  gdd <- sd(test_2)
  
  phy[n] <- ((gdd-91.186)*19)/175
}

town_label <- sort(unique(df$City))

plot_lon <- sapply(split(df$lon,df$City),mean)
plot_lat <- sapply(split(df$lat,df$City),mean)

par(bg="#83B799",family="serif",col.lab="black",col.axis="black",mar=c(4,4,2,1))
plot(0,type="n",xlim=c(-120,-117),ylim=c(46,48),xlab="Lon",ylab="Lat",
     main="Spring wheat phyllochrons for 24 locations in Washington derived from the posterior distribution of a multilevel model",axes=FALSE)
abline(v = -118, col = "#E2CD6D", lwd = 8000)
box()
axis(1,at=seq(-120,-116.5,0.5),las=1)
axis(2,at=seq(46,48,0.5),las=2)
points(x=plot_lon,y=plot_lat,pch=16,col="#CD3900")
text(x=plot_lon,y=plot_lat,labels=town_label,pos=3,cex=0.75,font=2)
text(x=plot_lon,y=plot_lat,labels=round(phy,digits=0),pos=1)
for(n in seq(-125,-115,0.5)){
  abline(v=n,lty=2,col="#CD3900")
}
for(n in seq(46,48,0.5)){
  abline(h=n,lty=2,col="#CD3900")
}

plot(precis(test_model_1,depth=2))


winter <- (post_1$a_season[,2])
spring <- (post_1$a_season[,1])

town_matrix <- matrix(NA,5000,24)
for (n in 1:24){
  town_matrix[,n] <- (post_1$a_town[,n])
}
year_label <- c(2015,2016,2017,2018)
year_matrix <- matrix(NA,5000,4)
for (n in 1:4){
  year_matrix[,n] <- (post_1$a_year[,n])
}

par(bg="#83B799",family="serif",col.lab="black",col.axis="black",mar=c(4,4,1,1))
plot(0,type="n",xlim=c(-1,0.75),ylim=c(-24,4),xlab="Marginal difference in GDD",ylab=" ",
     main=NULL,axes=FALSE)
abline(v = 0, col = "#E2CD6D", lwd = 8000)
box()
axis(1,at=gdd_seq_2,labels=gdd_seq,las=1)
axis(2,at=seq(-40,40,1),las=2)

for (i in seq(1,24,1)){
  points(y=-i,x=mean(town_matrix[,i]),pch=16,col="#CD3900")
  text(y=-i,x=mean(town_matrix[,i]),town_label[i],pos=4)
}
for (i in seq(1,4,1)){
  points(y=i,x=mean(year_matrix[,i]),pch=16,col="#CD3900")
  text(y=i,x=mean(year_matrix[,i]),year_label[i],pos=4)
}

abline(v=gdd_seq_2
       ,lty=2,col="#CD3900")

sd(df$gdd)
mean(df$gdd)

gdd_seq <- seq(-400,400,50)
gdd_seq_2 <- gdd_seq/sd(df$gdd)


