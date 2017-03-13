source(".Rprofile", local = TRUE)
print(.libPaths())
# Libraries ---------------------------------------------------------------
library(stringr)
library(ini)
library(dplyr)
library(magrittr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(tools)
 
setwd("../")
library(MetabolomiQCsR)
setwd("Files")

source("get_settings.R", local = TRUE)
source("find_new_files.R", local = TRUE)
source("parse_files.R", local = TRUE)
