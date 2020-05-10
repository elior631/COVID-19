if (!require("pacman")) install.packages("pacman")

pacman::p_load(
  tidyverse,   # for data wrangling and visualization
  tidymodels,  # for data modeling
  vip,         # for variable importance
  here,        # for referencing files and folders
  readxl       # for reading xlsx files
)

covid_raw <- 
  here( "data.csv") %>% 
  read_csv()

head(covid_raw)
