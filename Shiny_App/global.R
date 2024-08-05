# Libraries ---------------------------------------------------------------
library(plyr)
library(dplyr) # we do this in global to be sure we load dplyr after plyr
library(tidyr)
library(magrittr)
library(MetabolomiQCsR)
library(DBI)


# Establish connection
pool <- dbPool_MetabolomiQCs(120)

# Functions ---------------------------------------------------------------
stat_name2id <- . %>% paste0("SELECT * FROM std_stat_types WHERE stat_name = '",.,"'") %>% dbGetQuery(pool,.) %>% extract2("stat_id")


      
# Get enabled modules -----------------------------------------------------
module_names <- get_QC4Metabolomics_settings() %>% 
                  filter(!is.na(module)) %>% 
                  filter(grepl("shiny_enabled|shiny_order",name)) %>% 
                  mutate(type = gsub("^.*_(.*)$","\\1", name)) %>% 
                  pivot_wider(id_cols = "module", values_from = "value", names_from = "type") %>% 
                  filter(as.logical(enabled)) %>% 
                  arrange(as.integer(order)) %>% 
                  pull(module)


# Load modules ------------------------------------------------------------
module_names %>%
    rep(2) %>% 
    sort %>% 
    {paste0("../Modules/",.,"/",c("shiny_server.R","shiny_ui.R"))} %>% 
    {invisible(lapply(.,source))}
