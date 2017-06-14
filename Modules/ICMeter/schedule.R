# Libraries ---------------------------------------------------------------
library(magrittr)
library(rlist)
library(ini)
library(DBI)
library(dplyr)
library(tidyr)
library(pool)
library(httr)
library(lubridate)



setwd("../")
library(MetabolomiQCsR)
setwd("ICMeter")


source("get_settings.R", local = TRUE)
source("get_ICMeter_stats.R", local = TRUE)

