source(".Rprofile", local = TRUE)
print(.libPaths())

# Libraries ---------------------------------------------------------------
library(stringr)
library(ini)
library(xcms)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(magrittr)
library(purrr)
library(tidyr)
library(dplyr)

setwd("../")
library(MetabolomiQCsR)
setwd("TrackCmp")

source("get_settings.R", local = TRUE)
source("process_files.R", local = TRUE)
