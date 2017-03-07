LogUI <- function(id){
    
    require(DT)
    
    ns <- NS(id)
    
    tagList(
            tabPanel("Log",
        
                            fluidPage(
                                        dataTableOutput(ns("log_tbl"))
                                     )
                    )
    )
}
