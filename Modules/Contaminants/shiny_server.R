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


    source("../Modules/Contaminants/shiny_server/shiny_server_funs.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_header.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_overview.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_timeview.R",local=TRUE)
    source("../Modules/Contaminants/shiny_server/shiny_server_filescreening.R",local=TRUE)
 
}
