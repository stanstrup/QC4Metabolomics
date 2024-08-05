# Libraries ---------------------------------------------------------------
# library(stringr)
library(xcms)
library(DBI)
# library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(magrittr)
library(purrr)
library(tidyr)
library(dplyr)
library(MSnbase)
library(Spectra)


library(MetabolomiQCsR)
setwd("Modules/Contaminants")

source("process_files.R", local = TRUE)
