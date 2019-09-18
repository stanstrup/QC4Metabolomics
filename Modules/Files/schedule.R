# Libraries ---------------------------------------------------------------
library(stringr)
library(ini)
library(dplyr)
library(magrittr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(tools)
library(purrr)
library(tidyr)
 
library(MetabolomiQCsR)
setwd("Modules/Files")

source("get_settings.R", local = TRUE)
source("find_new_files.R", local = TRUE)
