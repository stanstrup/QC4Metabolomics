# Libraries ---------------------------------------------------------------
library(ini)
library(rlist)
library(shiny)
library(shinyjs)
library(pool)
library(DBI)
library(RMySQL)
library(MetabolomiQCsR)
library(DT)
library(plyr)
library(dplyr)
library(magrittr)
library(tidyr)
library(tibble)
library(plotly)
library(ggthemes)
library(zoo)
library(scales)


# Functions ---------------------------------------------------------------
stat_name2id <- . %>% paste0("SELECT * FROM std_stat_types WHERE stat_name = '",.,"'") %>% dbGetQuery(pool,.) %>% extract2("stat_id")


# Establish connection ----------------------------------------------------
pool <- dbPool_MetabolomiQCs(120)


# Get enabled modules -----------------------------------------------------
module_names <- "../Modules/conf.ini" %>%
                read.ini %>%
                list.filter(enabled == TRUE) %>%
                names


# Load modules ------------------------------------------------------------
module_names %>% 
    rep(2) %>% 
    sort %>% 
    {paste0("../Modules/",.,"/",c("shiny_server.R","shiny_ui.R"))} %>% 
    {invisible(lapply(.,source))}
