Log <- function(input, output, session, global_instruments_input){
  
  require(DBI)
  require(DT)
  require(dplyr)
  
  is_initialized <- dbGetQuery(pool, readLines("../Modules/Log/init_db_check.sql")) %>% {.[1,1]} %>% as.logical
  
  if (is_initialized) {
    source("../Modules/Log/shiny_server_log.R",local=TRUE)
  } else {
    showModal(modalDialog(
      title = "Error: Missing Tables for Log module",
      "Required tables are missing. Log module not loaded and the tab is not functional. The tables should be generated automatically soon. Hold on a few minutes.",
      easyClose = TRUE,
      footer = NULL
    ))
  }
  
  
}
