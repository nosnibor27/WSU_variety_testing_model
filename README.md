# WSU_variety_testing_model

## 1. Summary

This repository has all the code and data collected from the [WSU Variety Testing Program](http://smallgrains.wsu.edu/variety/)  to estimate 24 location-specific parameters for the CERES-Wheat model. I have [another repository](https://github.com/nosnibor27/WHEAT_phenology_forecaster) where I can use the CERES-Wheat model to subset daily climate data by developmental stage 

Subsetting daily climate data is performed by calculating the number of days needed to accumulate enough thermal time to progress to the next stage. Thermal time is measured in *growing degree-days* (GDD) which is very similar to summing daily average temperatures. This is the same approach to having an income column in $/day and calculating how many days it would take to save up enough money for a major purchase.

The CERES-Wheat model needs a `phyllochron` input parameter to determine the number of GDD needed for each stage. I've been using a default value of 100 GDD, and figured that the WSU variety testing reports had anough information publicly available for me to tinker with. The result is a map of `phyllochron` values below, which can be used with my [other repository](https://github.com/nosnibor27/WHEAT_phenology_forecaster) to provide more informed estimates of weather conditions during wheat developmental stages under climate change. The `phyllochron` is printed in red for winter wheat and blue for spring wheat.

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/phyllochron_map.png" alt="data dump"/>
</p>

 The information I pulled from the WSU variety testing reports was a planting date, a heading date, and GPS coordinates. There is code to query the appropriate grid in the [gritMET/METDATA](http://www.climatologylab.org/gridmet.html) dataset and download daily maximum and minimum temperature for the period of record (2015-2018) and calculate total GDD for a given range. I did not start collecting my climate data this way, originally I used [ClimEngine](https://clim-engine.appspot.com/) which is a wonderful tool to gather the same information through the browser.

The data was fed into a multilevel model, which may be a fancy way of saying that I assigned a unique parameter for each location, year, and season and let the computer sort out the probabilities for likely values of total GDD from planting date to heading date. If you are interested in the more technical aspects you can check my [first repository](https://github.com/nosnibor27/PHYTO) where I used the same approach to better understand sources of variability in noisy fungal count data across acres, fields, and seasons.

I also tested the modelling approach with the full dataset and a summarized version as well. I also include more analyses at the end describing the trade-offs to be considered when using more of the data that is available from the WSU Variety Testing Program.

## 3. Model Equation

The code for specifying the multilevel model using the `rethinking` package in R is attached below. The model can be referred to as "varying intercepts", and the "multilevel" or "hierarchical" term in the model is `a`. The parameters for each unique year, town, and season are modelled as offsets from `a`. The rest of the model specifies prior distributions. The code is translated into a format which can be utilized by [Stan](https://discourse.mc-stan.org/) to perform [Hamiltonian Monte Carlo](https://arxiv.org/abs/1701.02434). At the bottom are parameters for the Markov chain, which in this case results in 10000 total samples collected across 4 corees after a warmup-period of 1000 interations. The result is a list of 10000 values for a given parameter, the frequency of which corresponds to their relative plausibility given the data.

The data has not been standardized, and the prior for `a` is a normal distribution with a mean of 1500 and standard deviation of 300 GDD. This is approximately the mean and standard deviation of all 5729 observations (1528.38 ± 358.92 GDD). This keeps all the rsults in the appropriate units and simplifies downstream calculations while making the results more intuitive.

```r

test_model_1 <-  map2stan(
  alist(
    gdd ~ dnorm(mu,sigma),
    mu <- a + a_season[season] + a_town[town] + a_year[year],
    a_season[season] ~ dnorm(0,sigma_season),
    a_town[town] ~ dnorm(0,sigma_town),
    a_year[year] ~ dnorm(0,sigma_year),
    a ~ dnorm(1500,300),
    sigma_town ~ dexp(0.01),
    sigma_season ~ dexp(0.01),
    sigma_year ~ dexp(0.01),
    sigma <- dexp(0.01)
  ) ,
  data=list(gdd = df$gdd,
            town = df$City_f,
            year = df$Year_f,
            season = df$Season_f),
  warmup=1000,
  iter=3500,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.95,max_treedepth=14),
  verbose = TRUE
) 
```
I was curious to see if specifying a measurement error model with only the 91 unique location years could give similar answers as using the full dataset. There are many more years worth of data available from WSU which could be included in the analyses, and other university extension programs across the country could potentially have similar records. There are model comparisons below, and while the measurement error model runs faster the parameters for each location differ across models.

I can sample from the posterior distribution of samples from the multilevel model to estimate what likely phyllochron values would be expected for different locations. The remaining code details how I made the following maps, which show all the towns sampled and their respective phyllochron. I should mention that it is technically only the posterior mean, and that I have a whole distribution of phyllochron values as well. An example of a publishing results from more of the posterior distribution can be found in my [first repository](https://github.com/nosnibor27/PHYTO).

A winter wheat phyllochron map using the measurment error model is below. The results are roughly equivalent as when using the full dataset above.

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/phy_map_measurement_error.png" alt="data dump"/>
</p>

## 4. Model comparison

The marginal distribution of GDD differences by town is less when utilizing the measurement error model compared to the full dataset. I have mapped the posterior distribution of all 24 location parameters across both models below. The width along each axis is proportional to the standard deviation. There is a greater variability in the estimates when using the measurement error model, and the magnitude of the effects are greater when using the full dataset.

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/post_site_param_model_comparison.png" alt="data dump"/>
</p>

The multilevel model is a function of heterogenous intercepts, of which location was not the only cluster. The standard deviation in GDD for location parameters was ~90 GDD while the standard deviation in year parameters was ~14 GDD. There is more variance across years than across locations. This can be visualized by plotting the predictited standard deviation in GDD as a radius onto the above figure. The width of the green band is proportional to the standard deviation, and the ellipse shape is due to differences across models.

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/marginal_year_plot.png" alt="data dump"/>
</p>

The marginal distribution of GDD for each year in the dataset is below.

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/year_plot.png" alt="data dump"/>
</p>
