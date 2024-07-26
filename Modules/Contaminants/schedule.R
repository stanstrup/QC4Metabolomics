# Libraries ---------------------------------------------------------------
# library(stringr)
library(ini)
library(xcms)
library(DBI)
# library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(magrittr)
library(purrr)
library(tidyr)
library(dplyr)
library(MSnbase)


library(MetabolomiQCsR)
setwd("Modules/Contaminants")

source("get_settings.R", local = TRUE)
source("process_files.R", local = TRUE)
