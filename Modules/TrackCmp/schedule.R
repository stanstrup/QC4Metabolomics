# Libraries ---------------------------------------------------------------
library(stringr)
library(xcms)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(magrittr)
library(purrr)
library(tidyr)
library(dplyr)
library(MSnbase)
library(MetabolomiQCsR)

setwd("Modules/TrackCmp")

source("process_files.R", local = TRUE)
