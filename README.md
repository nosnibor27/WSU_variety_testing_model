# Attempting to calibrate a wheat model using planting and heading dates from WSU's Variety Testing Program

## 1. Loading and processing the data

'''r

'''

## 2. Model Specifications
'''r
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
'''r
## 3. Model output

