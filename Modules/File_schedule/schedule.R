# Libraries ---------------------------------------------------------------
library(magrittr)
library(rlist)
library(ini)
library(DBI)
library(dplyr)
library(tidyr)
library(pool)

library(MetabolomiQCsR)
setwd("Modules/File_schedule")


source("get_settings.R", local = TRUE)
source("schedule_new_files.R", local = TRUE)

