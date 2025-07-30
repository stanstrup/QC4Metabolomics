Warner <- function(input, output, session, global_instruments_input){

    require(glue)
    require(DBI)
    require(magrittr)
    require(dplyr)
    require(purrr)
    require(pool)
    require(DT)
    require(tidyr)
    require(blastula)
    require(htmltools)

    is_initialized <- dbGetQuery(pool, readLines("../Modules/Warner/init_db_check.sql")) %>% {.[1,1]} %>% as.logical

    
    if (is_initialized) {
      source("../Modules/Warner/shiny_server_rules.R",local=TRUE)
    } else {
      showModal(modalDialog(
        title = "Error: Missing Tables for Warner module",
        "Required tables are missing. Warner module not loaded and the tab is not functional. The tables should be generated automatically soon. Hold on a few minutes.",
        easyClose = TRUE,
        footer = NULL
      ))
    }
    

}
