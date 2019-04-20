library(stringr)
library(RNetCDF)
library(zoo)
library(rethinking)

#loading in dataframe (df)
df = read.csv(file = "WSU_variety_testing_2015_2018.csv", stringsAsFactors = FALSE)

#adding unique location years
df$unique <- paste0(df$City,"_",df$Season,"_",df$Year)



unique_matrix <- matrix(NA,91,3)
unique_matrix[,1] <- as.vector(sapply(split(df$lon,df$unique),max))
unique_matrix[,2] <- as.vector(sapply(split(df$lat,df$unique),max))
unique_matrix[,3] <- unique(df$unique)


df$lon_1 <- str_replace(df$Longitude,"W","")
df$lat_1 <- str_replace(df$Latitude,"N","")

df$lon_2 <- as.numeric(word(df$lon_1,1))
df$lon_3 <- as.numeric(word(df$lon_1,2))
df$lat_2 <- as.numeric(word(df$lat_1,1))
df$lat_3 <- as.numeric(word(df$lat_1,2))

df$lon <- -(df$lon_2+(df$lon_3/60))
df$lat <- df$lat_2+(df$lat_3/60)

df$hd_1 <- as.character(as.Date(as.character(df$Head_Date),"%j"))

df$hd_2 <- str_remove(df$hd_1,"2019")

df$hd <- as.Date(paste0(df$Year,df$hd_2))

df$pd <- as.Date(df$Planting_Date,"%m/%d/%Y")

df$gdd <- rep(NA,N)
#base url
url_2 <- "http://thredds.northwestknowledge.net:8080/thredds/dodsC/MET/"

#year list to query
year_list <- c("2014.nc",
               "2015.nc",
               "2016.nc",
               "2017.nc",
               "2018.nc")

#variable list
variable_1 <- c("tmmx/tmmx_","tmmn/tmmn_")

#list of days for the count argument
day_list <- c(365,365,366,365,365)

N <- nrow(df)
i <- 1
n <- 1

ref_date <- as.Date(seq(41638,43463,1),origin="1900-01-01")
ref_zoo = read.zoo(as.data.frame(ref_date),format = "%Y-%m-%d")
ref_index = index(ref_zoo)

#function to calculate growing degree-days (GDD) with a base temp of 0 C
GDD <- function(max_temp,min_temp){
  ifelse((((max_temp-273.15)+(min_temp-273.15))/2)<0,0,
         (((max_temp-273.15)+(min_temp-273.15))/2))
}

#collecting data by row

#collecting data by row
for (n in 1:nrow(unique_matrix)){
  #starting a matrix for GDD values
  gdd <- matrix(NA,1826,3)
  #collecting maximum and minimum temperatures for all years in range
  for (i in 1:2){
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
    gdd[,i] <- var
  }
  #calculating GDD
  gdd[,3] <- GDD(gdd[,1],gdd[,2])
  assign(paste0(unique_matrix[n,3],"_gdd"),gdd)
  #printing progress
  print(n)
}


df$gdd <- NA

for(n in 1:nrow(df)){
  A <- get(paste0(df$City[n],"_",df$Season[n],"_",df$Year[n],"_gdd"))
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
  #calculating sum
  total_gdd <- sum(A[(lookup[1]:lookup[2]),3])
  #adding to dataframe
  df$gdd[n] <- total_gdd
  #printing progress
  print(n)
}

df$gdd_s <- (df$gdd-mean(df$gdd))/sd(df$gdd)


df$City_f <- as.numeric(factor(df$City))
df$Year_f <- as.numeric(factor(df$Year))
df$Season_f <- as.numeric(factor(df$Season))

data_list <- list(gdd = df$gdd_s,
                  town = df$City_f,
                  year = df$Year_f,
                  season = df$Season_f)

test_model <-  map2stan(
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
  data=data_list,
  warmup=1000,
  iter=3500,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.99,max_treedepth=15),
  verbose = TRUE
)                

precis(test_model,depth=2)

posterior <- extract.samples(test_model,10000)

postcheck(test_model,window = 100)

town_matrix <- as.matrix(posterior$a_town)

town_matrix <- town_matrix*sd(df$gdd)

apply(town_matrix,2,mean)
apply(town_matrix,2,sd)

plot(x=df$lon,y=df$lat)
text(x=df$lon,y=df$lat,labels = df$City)
