TrackCmp <- function(input, output, session, global_instruments_input){

    require(DBI)
    require(magrittr)
    require(dplyr)
    require(pool)
    require(DT)
    require(tidyr)

    source("../Modules/TrackCmp/shiny_server_stats.R",local=TRUE)
    source("../Modules/TrackCmp/shiny_server_cmp.R",local=TRUE)
    
}
