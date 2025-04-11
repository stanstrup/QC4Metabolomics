# Libraries ---------------------------------------------------------------
library(stringr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(magrittr)
library(purrr)
library(tidyr)
library(dplyr)
library(MetabolomiQCsR)

setwd("Modules/Warner")

source("process_files.R", local = TRUE)
