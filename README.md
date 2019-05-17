# WSU_variety_testing_model

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/plots/Pullman_winter.png" alt="data dump"/>
</p>

## 1. Background

  This repository has all the code and data from the [WSU Variety Testing Program](http://smallgrains.wsu.edu/variety/) used to estimate 24 location-specific parameters for the CERES-Wheat model. I have [another repository](https://github.com/nosnibor27/WHEAT_phenology_forecaster) where I use the CERES-Wheat model to subset daily climate data by developmental stage. This is performed by calculating the number of days needed to accumulate enough thermal time to progress to the next stage. Thermal time is measured in *growing degree-days* (GDD) which is very similar to summing daily average temperatures.

  The CERES-Wheat model needs a *phyllochron* input parameter to determine the number of GDD needed for each stage. I've been using a default value of 100 GDD, and figured that the WSU variety testing reports had anough information publicly available for me to tinker with.

  The information I pulled from the WSU variety testing reports was a planting date, a heading date, and GPS coordinates. There is code to query the appropriate grid in the [gritMET/METDATA](http://www.climatologylab.org/gridmet.html) dataset and download daily maximum and minimum temperature for the period of record (2015-2018) and calculate total GDD for a given range. I did not start collecting my climate data this way, originally I used [ClimEngine](https://clim-engine.appspot.com/) which is a wonderful tool to gather the same information through the browser.

The data was fed into a multilevel model, which may be a fancy way of saying that I assigned a unique parameter for each location, year, and season and let the computer sort out the probabilities for likely values of total GDD. If you are interested in the more technical aspects you can check my [first repository](https://github.com/nosnibor27/PHYTO) where I used the same approach to better understand sources of variability in noisy fungal count data across acres, fields, and seasons.

The result is now I can use 183 GDD as a phyllochron when forecasting for Pullman, WA. I have coefficients for 24 towns, but I've only used a small subset of the total variety testing data available. The model is scalable to new data, and estimates can change given new information.

## 2. Loading and processing the data

The code is commented and begins by importing `WSU_variety_testing_2015_2018.csv` and doing some string manipulation to capitalize town names and convert the latitude and longitude into a decimal degrees. There is data from 91 unique combinations of location, season, and year which we can print as a matrix using `matrix(c(unique(df$unique),rep(NA,9)),25,4)`. In the printout you can see which PDFs were used in the multilevel model

```r
     [,1]                       [,2]                       [,3]                      [,4]                     
 [1,] "Dayton_winter_2015"       "Creston_winter_2016"      "Lind_winter_2017"        "Lind_winter_2018"       
 [2,] "Connell_winter_2015"      "Dayton_winter_2016"       "Lind_spring_2017"        "Lind_spring_2018"       
 [3,] "Lamont_winter_2015"       "Dayton_spring_2016"       "Mayview_winter_2017"     "Mayview_winter_2018"    
 [4,] "Pullman_winter_2015"      "Fairfield_winter_2016"    "Plaza_spring_2017"       "Moses Lake_winter_2018" 
 [5,] "Ritzville_winter_2015"    "Farmington_spring_2016"   "Pullman_winter_2017"     "Pasco_winter_2018"      
 [6,] "Walla Walla_winter_2015"  "Farmington_winter_2016"   "Pullman_spring_2017"     "Plaza_spring_2018"      
 [7,] "Almira_spring_2015"       "Horse Heaven_spring_2016" "Reardan_winter_2017"     "Pullman_winter_2018"    
 [8,] "Dayton_spring_2015"       "Lamont_winter_2016"       "Ritzville_winter_2017"   "Pullman_spring_2018"    
 [9,] "Endicott_spring_2015"     "Lind_winter_2016"         "St. John_winter_2017"    "Reardan_winter_2018"    
[10,] "Farmington_spring_2015"   "Lind_spring_2016"         "Walla Walla_winter_2017" "Reardan_spring_2018"    
[11,] "Horse Heaven_spring_2015" "Mayview_spring_2016"      "Almira_winter_2018"      "Ritzville_winter_2018"  
[12,] "Lamont_spring_2015"       "Plaza_spring_2016"        "Anatone_winter_2018"     "St. Andrews_winter_2018"
[13,] "Mayview_spring_2015"      "Pullman_spring_2016"      "Colton_winter_2018"      "St. John_spring_2018"   
[14,] "Pullman_spring_2015"      "Reardan_spring_2016"      "Connell_winter_2018"     "St. John_winter_2018"   
[15,] "St. John_spring_2015"     "St. John_spring_2016"     "Creston_winter_2018"     "Walla Walla_winter_2018"
[16,] "Almira_winter_2015"       "St. John_winter_2016"     "Dayton_winter_2018"      "Walla Walla_spring_2018"
[17,] "Colton_winter_2015"       "Walla Walla_winter_2016"  "Dayton_spring_2018"      NA                       
[18,] "Dusty_winter_2015"        "Anatone_winter_2017"      "Dusty_winter_2018"       NA                       
[19,] "Lind_winter_2015"         "Colton_winter_2017"       "Eureka_winter_2018"      NA                       
[20,] "Mayview_winter_2015"      "Connell_winter_2017"      "Fairfield_spring_2018"   NA                       
[21,] "St. John_winter_2015"     "Creston_winter_2017"      "Fairfield_winter_2018"   NA                       
[22,] "Almira_winter_2016"       "Dayton_spring_2017"       "Farmington_spring_2018"  NA                       
[23,] "Almira_spring_2016"       "Dusty_winter_2017"        "Farmington_winter_2018"  NA                       
[24,] "Colton_winter_2016"       "Eureka_winter_2017"       "Lamont_winter_2018"      NA                       
[25,] "Connell_winter_2016"      "Fairfield_winter_2017"    "Lamont_spring_2018"      NA         
```
There is also code for manipulating dates, downloading data from NetCDF files, calculating a sum, and preparing lists of data for the multilevel model.

## 3. Model Equation

The code for specifying the multilevel model using the `rethinking` package in R is attached below. The model can be referred to as "varying intercepts", and the "multilevel" or "hierarchical" term in the model is `a`. The parameters for each unique year, town, and season are modelled as offsets from `a`. The rest of the model specifies prior distributions. The code is translated into a format which can be utilized by [Stan]() to perform [Hamiltonian Monte Carlo](). At the bottom are parameters for the Markov chain, which in this case results in 5000 total samples collected across 4 corees after a warmup-period of 1000 interations. The result is a list of 5000 values for a given parameter, the frequency of which corresponds to their relative plausibility given the data.

Essentially, I am using a computer like a bookmaker to calculate odds given the data.

```r
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
  warmup=1000,
  iter=2250,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.99,max_treedepth=15),
  verbose = TRUE
) 
```

## 4. Making sense of the output

I can sample from the posterior distribution of samples from the multilevel model to estimate what likely phyllochron values would be expected for different locations. The remaining code details how I made the following maps, which show all the towns sampled and their respective phyllochron. I should mention that it is technically only the posterior mean, and that I have a whole distribution of phyllochron values as well. An example of a publishing results from more of the posterior distribution can be found in my [first repository](https://github.com/nosnibor27/PHYTO). 

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/plots/phy_map_winter.png" alt="data dump"/>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/plots/phy_map_spring.png" alt="data dump"/>
</p>

