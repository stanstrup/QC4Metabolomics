Contaminants <- function(input, output, session, global_instruments_input){

    require(DBI)
    require(pool)
    require(ggplot2)
    require(lubridate)
    require(viridis)
    require(ggthemes)
    require(plotly)
    require(dplyr)
    require(magrittr)
    require(scales)
    require(zoo)
    require(stringr)


  is_initialized <- dbGetQuery(pool, readLines("../Modules/Contaminants/init_db_check.sql")) %>% {.[1,1]} %>% as.logical
  
  
  if (is_initialized) {
    source("../Modules/Contaminants/shiny_server/shiny_server_funs.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_header.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_overview.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_timeview.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_filescreening.R",local=TRUE)
  } else {
    showModal(modalDialog(
      title = "Error: Missing Tables for Contaminants module",
      "Required tables are missing. Contaminants module not loaded and the tab is not functional. The tables should be generated automatically soon. Hold on a few minutes.",
      easyClose = TRUE,
      footer = NULL
    ))
  }
  
  
}
