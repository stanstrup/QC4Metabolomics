# Libraries ---------------------------------------------------------------
library(plyr)
library(dplyr) # we do this in global to be sure we load dplyr after plyr
library(ini)
library(rlist)
library(magrittr)
library(MetabolomiQCsR)


# Establish connection
pool <- dbPool_MetabolomiQCs(120)

# Init enabled modules if not already done
source("init_db.R")


# Functions ---------------------------------------------------------------
stat_name2id <- . %>% paste0("SELECT * FROM std_stat_types WHERE stat_name = '",.,"'") %>% dbGetQuery(pool,.) %>% extract2("stat_id")


# Get enabled modules -----------------------------------------------------
module_names <- MetabolomiQCsR.env$general$settings_file %>% 
                read.ini %>%
                list.match("module_.*") %>% 
                list.filter(shiny_enabled == TRUE) %>%
                names %>% 
                gsub("module_","",.)


# Load modules ------------------------------------------------------------
module_names %>%
    rep(2) %>% 
    sort %>% 
    {paste0("../Modules/",.,"/",c("shiny_server.R","shiny_ui.R"))} %>% 
    {invisible(lapply(.,source))}
