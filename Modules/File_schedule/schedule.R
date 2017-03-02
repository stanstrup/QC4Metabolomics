# Libraries ---------------------------------------------------------------
library(magrittr)
library(rlist)
library(ini)

library(MetabolomiQCsR)
library(DBI)
library(dplyr)
library(tidyr)
library(pool)

setwd("../")
library(MetabolomiQCsR)
setwd("File_schedule")


source("get_settings.R", local = TRUE)
source("schedule_new_files.R", local = TRUE)

