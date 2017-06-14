tabPanel("IC-Meters",
                            fluidPage(
                                
                                        fluidRow(
                                                    column(2,uiOutput(ns("file_date_range_ui")))
                                                ),
                            
                                        
                                        br(),br(),br(),
                                            
                                        tabsetPanel(
                                                      tabPanel("Over time",
                                                               
                                                               div(style = "width: 1400px; margin:0 auto;",
                                                                        uiOutput(ns("timeplots"))
                                                                  )
                                                               
                                                                
                                                               
                                                               
                                                              ) 
                                        )
                                        
                                        
                                        
                                    )
        )
