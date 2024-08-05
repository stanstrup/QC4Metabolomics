# Libraries ---------------------------------------------------------------
library(stringr)
library(dplyr)
library(magrittr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(tools)
 
library(MetabolomiQCsR)
setwd("Modules/FileInfo")

source("parse_files.R", local = TRUE)
