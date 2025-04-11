WarnerUI <- function(id){
    
    require(shinyjs)
    
    ns <- NS(id)
    
      source("../Modules/Warner/shiny_ui_rules.R", local=TRUE)$value


}
