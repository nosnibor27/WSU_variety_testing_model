# Attempting to calibrate a wheat model using planting and heading dates from WSU's Variety Testing Program

## 1. Background

I have another repository wherein I adapt a wheat model to subset daily climate data by developmental stages. I can use the resulting index locations to calculate values such as average relative humidity during tillering or total rainfall during grain fill. The purpose of all the indexing is realized when combining the wheat model with the daily output of global climate models to forecast weather conditions during different developmental stages under climate change. The original motivation was to forecast Fusarium head blight risk by evaluating if weather conditions during flowering were expected to become more hot and humid under climate change for a particular location in the continental United States

The issue is that the wheat model has several input parameters and they are currently set to the default recommended values. 

## 2. Loading and processing the data

```r
df = read.csv(file = "WSU_variety_testing_2015_2018.csv", stringsAsFactors = FALSE)

N <- nrow(df)

df$City <- str_to_title(df$City)

df$unique <- paste0(df$City,"_",df$Season,"_",df$Year)
```

To visualize all unique combinations of location, season, and year we can print a matrix using `matrix(c(unique(df$unique),rep(NA,9)),25,4)`. In the printout you can see

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

## 3. The model

```r
data_list_1 <- list(gdd = df$gdd_s,
                    town = df$City_f,
                    year = df$Year_f,
                    season = df$Season_f)

test_model_1 <-  map2stan(
  alist(
    gdd ~ dnorm(mu,sigma),
    mu <- a + a_season[season] + a_town[town] + a_year[year],
    a_season[season] ~ dnorm(0,sigma_season),
    a_town[town] ~ dnorm(0,sigma_town),
    a_year[year] ~ dnorm(0,sigma_year),
    a ~ dnorm(0,0.5),
    sigma_town ~ dexp(0.5),
    sigma_season ~ dexp(0.5),
    sigma_year ~ dexp(0.5),
    sigma <- dexp(0.5)
  ) ,
  data=data_list_1,
  warmup=500,
  iter=1000,
  chains=4,
  cores=4,
  control = list(adapt_delta = 0.99,max_treedepth=15),
  verbose = TRUE
) 
```

## 4. Making sense of the output

<p align="center">
  <img src="https://raw.githubusercontent.com/nosnibor27/WSU_variety_testing_model/master/plots/phy_map_winter.png" width="1200" height="800" alt="data dump"/>
</p>

## 5. Running the CERES-Wheat model with updated phyllochrons


