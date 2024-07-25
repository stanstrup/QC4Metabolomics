ICMeterUI <- function(id){
    
    require(plotly)
    
    ns <- NS(id)
    
    
            source("../Modules/ICMeter/shiny_ui_timeplots.R", local=TRUE)$value
    
}
