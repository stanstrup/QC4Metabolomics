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

    source("../Modules/Warner/shiny_server_rules.R",local=TRUE)
    
}
