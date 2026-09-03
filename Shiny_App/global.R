# Libraries ---------------------------------------------------------------
# Suppress masking/attaching noise; real errors still propagate.
.quiet_load <- function(expr) {
    withCallingHandlers(
        suppressPackageStartupMessages(expr),
        message = function(m) {
            if (grepl("masked from|Attaching package|Loading required package|Welcome to Bioconductor|Visit https|Consider switching|This is.*version",
                      conditionMessage(m), perl = TRUE))
                invokeRestart("muffleMessage")
        },
        warning = function(w) {
            if (grepl("replacing previous import", conditionMessage(w)))
                invokeRestart("muffleWarning")
        }
    )
}

.quiet_load({
    library(plyr)
    library(dplyr) # load after plyr so dplyr wins masking conflicts
    library(tidyr)
    library(magrittr)
    library(MetabolomiQCsR)
    library(DBI)
    # Pre-load all packages required by module shiny_server/ui files so
    # their require() calls are no-ops and emit no masking messages.
    library(pool)
    library(ggplot2)
    library(plotly)
    library(ggthemes)
    library(viridis)
    library(scales)
    library(zoo)
    library(lubridate)
    library(stringr)
    library(purrr)
    library(glue)
    library(fs)
    library(DT)
    library(shinyjs)
    library(blastula)
    library(htmltools)
})


# Establish connection
pool <- dbPool_MetabolomiQCs(120)

# Functions ---------------------------------------------------------------
stat_name2id <- . %>% paste0("SELECT * FROM std_stat_types WHERE stat_name = '",.,"'") %>% dbGetQuery(pool,.) %>% extract2("stat_id")


      
# Get enabled modules -----------------------------------------------------
module_names <- get_QC4Metabolomics_settings() %>% 
                  filter(!is.na(module)) %>% 
                  filter(grepl("_enabled|shiny_enabled|shiny_order",name)) %>% 
                  mutate(type = gsub("^QC4METABOLOMICS_module_.*?_(.*)$","\\1", name)) %>% 
                  pivot_wider(id_cols = "module", values_from = "value", names_from = "type") %>% 
                  arrange(module) %>%                                 
                  filter(as.logical(enabled) & as.logical(shiny_enabled)) %>% 
                  arrange(as.integer(shiny_order)) %>%                 
                  pull(module)


# Load modules ------------------------------------------------------------
module_names %>%
    rep(2) %>% 
    sort %>% 
    {paste0("../Modules/",.,"/",c("shiny_server.R","shiny_ui.R"))} %>% 
    {invisible(lapply(.,source))}
