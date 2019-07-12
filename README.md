# WSU_variety_testing_model

## 1. Summary

This repository has all the code and data collected from the [WSU Variety Testing Program](http://smallgrains.wsu.edu/variety/)  to estimate 24 location-specific parameters for the CERES-Wheat model. I have [another repository](https://github.com/nosnibor27/WHEAT_phenology_forecaster) where I can use the CERES-Wheat model to subset daily climate data by developmental stage 

Subsetting daily climate data is performed by calculating the number of days needed to accumulate enough thermal time to progress to the next stage. Thermal time is measured in *growing degree-days* (GDD) which is very similar to summing daily average temperatures. This is the same approach to having an income column in $/day and calculating how many days it would take to save up enough money for a major purchase.

The CERES-Wheat model needs a *phyllochron* input parameter to determine the number of GDD needed for each stage. I've been using a default value of 100 GDD, and figured that the WSU variety testing reports had anough information publicly available for me to tinker with. The result is a map of phyllochron values below, which can be used with my [other repository](https://github.com/nosnibor27/WHEAT_phenology_forecaster) to provide more informed estimates of weather conditions during wheat developmental stages under climate change.

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/phy_map_full_dataset.png" alt="data dump"/>
</p>

 The information I pulled from the WSU variety testing reports was a planting date, a heading date, and GPS coordinates. There is code to query the appropriate grid in the [gritMET/METDATA](http://www.climatologylab.org/gridmet.html) dataset and download daily maximum and minimum temperature for the period of record (2015-2018) and calculate total GDD for a given range. I did not start collecting my climate data this way, originally I used [ClimEngine](https://clim-engine.appspot.com/) which is a wonderful tool to gather the same information through the browser.

The data was fed into a multilevel model, which may be a fancy way of saying that I assigned a unique parameter for each location, year, and season and let the computer sort out the probabilities for likely values of total GDD. If you are interested in the more technical aspects you can check my [first repository](https://github.com/nosnibor27/PHYTO) where I used the same approach to better understand sources of variability in noisy fungal count data across acres, fields, and seasons.

I also tested the modelling approach with the full dataset and a summarized version as well. I also include more analyses at the end describing the trade-offs to be considered when using more of the data that is available from the WSU Variety Testing Program.

## 2. Loading and processing the data

The code is commented and begins by importing `WSU_variety_testing_2015_2018.csv` and doing some string manipulation to capitalize town names and convert the latitude and longitude into a decimal degrees. There is data from 91 unique combinations of location, season, and year.

I can print the names of all 90 location-years with `matrix(c(unique(df$unique),rep(NA,9)),25,4)`. In the printout you can see which PDFs were used in the multilevel model. There is additional data on the WSU Vriety Testing website, but it will take additional time to incorporate into an appropriate format. As it currently stands, the full dataset has 5729 observations. I also tested the same modelling equation using just the means and standard deviations of the 91 location years below.

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


<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/post_site_param_model_comparison.png" alt="data dump"/>
</p>


<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/phy_map_measurement_error.png" alt="data dump"/>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/marginal_year_plot.png" alt="data dump"/>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/year_plot.png" alt="data dump"/>
</p>


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

The code for specifying the multilevel model using the `rethinking` package in R is attached below. The model can be referred to as "varying intercepts", and the "multilevel" or "hierarchical" term in the model is `a`. The parameters for each unique year, town, and season are modelled as offsets from `a`. The rest of the model specifies prior distributions. The code is translated into a format which can be utilized by [Stan](https://discourse.mc-stan.org/) to perform [Hamiltonian Monte Carlo](https://arxiv.org/abs/1701.02434). At the bottom are parameters for the Markov chain, which in this case results in 5000 total samples collected across 4 corees after a warmup-period of 1000 interations. The result is a list of 5000 values for a given parameter, the frequency of which corresponds to their relative plausibility given the data.

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

I can sample from the posterior distribution of samples from the multilevel model to estimate what likely phyllochron values would be expected for different locations. The remaining code details how I made the following maps, which show all the towns sampled and their respective phyllochron. I should mention that it is technically only the posterior mean, and that I have a whole distribution of phyllochron values as well. An example of a publishing results from more of the posterior distribution can be found in my [first repository](https://github.com/nosnibor27/PHYTO). Click on the images below for a larger map.
