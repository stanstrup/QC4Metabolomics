LogUI <- function(id){
    
    require(DT)
    
    ns <- NS(id)
    
    
            tabPanel("Log",
        
                            fluidPage(
                                        dataTableOutput(ns("log_tbl"))
                                     )
                    )
    
}
