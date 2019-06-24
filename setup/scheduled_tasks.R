message("====================================================\nRunning scheduled tasks at: ", Sys.time(), "\n====================================================")

setwd("/srv/shiny-server/QC4Metabolomics/")
source(".Rprofile")


# Libraries ---------------------------------------------------------------
library(dplyr) # we do this in global to be sure we load dplyr after plyr
library(ini)
library(rlist)
library(MetabolomiQCsR)


# Init enabled modules if not already done---------------------------------
source("setup/init_db.R")


# Get enabled modules -----------------------------------------------------
module_names <- MetabolomiQCsR.env$general$settings_file %>% 
  read.ini %>%
  list.match("module_.*") %>% 
  list.filter(schedule == TRUE) %>%
  # list.sort(file_schedule) %>% 
  names %>% 
  gsub("module_","",.)


# Run scheduled -----------------------------------------------------------
module_names %>%
  sort %>% 
  {paste0("Modules/",.,"/","schedule.R")} %>%
  paste0('/usr/local/bin/Rscript \"',.,'\"') %>% 
  {invisible(lapply(.,system))}

