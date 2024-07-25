DebugUI <- function(id){
    
    require(DT)
    
    ns <- NS(id)


            tabPanel("Debug",
                                        fluidPage(
                                            
                                        
                                            h4("Working directory"),
                                            verbatimTextOutput(ns("wd")),
                                            
                                            br(),
                                            
                                            h4("Session Info"),
                                            verbatimTextOutput(ns("sessionInfo")),
                                            
                                            br(),
                                            
                                            h4("Installed packages in renv"),
                                            dataTableOutput(ns("packages_packrat")),
                                            
                                            br(),
                                            
                                            h4("Installed packages NOT in renv"),
                                            dataTableOutput(ns("packages"))
                                        )
                    )


}
