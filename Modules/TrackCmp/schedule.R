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
library(purrrlyr)
library(MSnbase)
library(parallelly)
library(furrr)

plan(multicore, workers = pmax(availableCores()-1, 1))

library(MetabolomiQCsR)
setwd("Modules/TrackCmp")

source("get_settings.R", local = TRUE)
source("process_files.R", local = TRUE)
