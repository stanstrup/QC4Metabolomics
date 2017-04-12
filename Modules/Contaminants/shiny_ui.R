ContaminantsUI <- function(id){
    
    require(plotly)
    
    ns <- NS(id)
    
    tagList(
            source("../Modules/Contaminants/shiny_ui_overview.R", local=TRUE)$value
    )
}
