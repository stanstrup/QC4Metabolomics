TrackCmpUI <- function(id){
    
    require(plotly)
    require(shinyjs)
    require(DT)
    
    ns <- NS(id)
    
    navbarMenu("Track compounds",

                    source("../Modules/TrackCmp/shiny_ui_stats.R", local=TRUE)$value,
                    source("../Modules/TrackCmp/shiny_ui_cmp.R", local=TRUE)$value
            )
}
