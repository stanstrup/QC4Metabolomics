LogUI <- function(id){
    ns <- NS(id)

    tabPanel("Log",

                    fluidPage(
                                dataTableOutput(ns("log_tbl"))
                             )
            )
}
