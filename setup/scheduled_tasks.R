message("====================================================\nRunning scheduled tasks at: ", Sys.time(), "\n====================================================")

setwd("/srv/shiny-server/QC4Metabolomics/")
source(".Rprofile")


# Libraries ---------------------------------------------------------------
library(dplyr) # we do this in global to be sure we load dplyr after plyr
library(MetabolomiQCsR)
library(stringr)


# Init enabled modules if not already done---------------------------------
source("setup/init_db.R")


# Get enabled modules -----------------------------------------------------
module_names <- get_QC4Metabolomics_settings() %>% 
                      filter(grepl("^QC4METABOLOMICS_module_.*?_schedule$|^QC4METABOLOMICS_module_.*?_process_order$",name)) %>%
                      filter(!grepl("^QC4METABOLOMICS_module_.*?_file_schedule$",name)) %>%
                      mutate(type = gsub("^.*_(.*)$","\\1", name)) %>% 
                      pivot_wider(id_cols = "module", values_from = "value", names_from = "type") %>% 
                      mutate(schedule = as.logical(schedule), order = as.integer(order)) %>%
                      filter(schedule == TRUE) %>% 
                      mutate(order = if_else(is.na(order), Inf, order)) %>% 
                      arrange(order) %>% 
                      pull(module)



# Run scheduled -----------------------------------------------------------
module_names %>%
  {paste0("Modules/",.,"/","schedule.R")} %>%
  paste0('cd ',getwd(),' && /usr/local/bin/Rscript \"',.,'\"') %>% 
  {print(.);invisible(lapply(.,system))}

