TrackCmp <- function(input, output, session, global_instruments_input){

  require(DBI)
  require(magrittr)
  require(dplyr)
  require(pool)
  require(DT)
  require(tidyr)
  
  
  is_initialized <- dbGetQuery(pool, readLines("../Modules/TrackCmp/init_db_check.sql")) %>% {.[1,1]} %>% as.logical
  
  
  if (is_initialized) {
    source("../Modules/TrackCmp/shiny_server_stats.R",local=TRUE)
    source("../Modules/TrackCmp/shiny_server_cmp.R",local=TRUE)
  } else {
    showModal(modalDialog(
      title = "Error: Missing Tables for TrackCmp module",
      "Required tables are missing. TrackCmp module not loaded and the tab is not functional. The tables should be generated automatically soon. Hold on a few minutes.",
      easyClose = TRUE,
      footer = NULL
    ))
  }
  
  
    
}
