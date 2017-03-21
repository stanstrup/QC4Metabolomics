tabPanel("Productivity",
                            fluidPage(
                                
                                        fluidRow(
                                                    column(2,
                                                            uiOutput(ns("project_select_ui")),
                                                            actionButton(ns("resetButton"), "Reset filters")
                                                           ),
                                                    column(2,uiOutput(ns("mode_select_ui"))),
                                                    column(2,
                                                               textInput(ns("sample_id"), "Sample ID", ""),
                                                               checkboxInput(ns("sample_id_inv"), label = "Inverse", value = FALSE),
                                                               helpText(HTML('<a href="https://www.tutorialspoint.com/mysql/mysql-regexps.htm">REGEXP</a>  supported.'))
                                                           ),
                                                    column(2,uiOutput(ns("file_date_range_ui")))
                                                ),
                            
                                        
                                        br(),br(),br(),
                                            
                                        tabsetPanel(
                                                      tabPanel("Heatmap",
                                                               
                                                               div(style = "width: 1400px; margin:0 auto;",
                                                                        # plotlyOutput(ns("heatmap"), width = "1400px", height="900px"),
                                                                        uiOutput(ns("heatmaps"))
                                                                  )
                                                               
                                                                
                                                               
                                                               
                                                              ) 
                                        )
                                        
                                        
                                        
                                    )
        )
