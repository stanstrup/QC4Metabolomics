TrackCmpUI <- function(id){
    ns <- NS(id)

    tabPanel("Standard stats",
                                fluidPage(
                                    
                                            fluidRow(
                                                        column(2,
                                                                uiOutput(ns("std_stats_project_select_ui")),
                                                                actionButton(ns("std_stats_resetButton"), "Reset filters")
                                                               ),
                                                        column(2,uiOutput(ns("std_stats_mode_select_ui"))),
                                                        column(2,
                                                                   textInput(ns("std_stats_sample_id"), "Sample ID", ""),
                                                                   checkboxInput(ns("std_stats_sample_id_inv"), label = "Inverse", value = FALSE),
                                                                   helpText(HTML('<a href="https://www.tutorialspoint.com/mysql/mysql-regexps.htm">REGEXP</a>  supported.'))
                                                               ),
                                                        column(2,uiOutput(ns("file_date_range_ui")))
                                                    ),
                                
                                            
                                            br(),br(),br(),
                                                
                                            tabsetPanel(
                                                          tabPanel("Deviations",
                                                                   
                                                                   div(style = "max-width: 1000px; width: 100%; max-height: 500px; height: 100%; margin:0 auto;",
                                                                            plotlyOutput(ns("std_stats_rtplot"), width = "100%", height="100%"),
                                                                            br(),
                                                                            br(),
                                                                            plotlyOutput(ns("std_stats_mzplot"), width = "100%", height="100%")
                                                                      )
                                                                   
                                                                   
                                                                  ) ,
                                                          
                                                          
                                                          tabPanel("Peak shapes",
                                                                   
                                                                   div(style = "max-width: 1000px; width: 100%; max-height: 500px; height: 100%; margin:0 auto;",
                                                                            plotlyOutput(ns("std_stats_fwhmplot"), width = "100%", height="100%"),
                                                                            br(),
                                                                            br(),
                                                                            plotlyOutput(ns("std_stats_TFplot"), width = "100%", height="100%"),
                                                                            br(),
                                                                            br(),
                                                                            plotlyOutput(ns("std_stats_AFplot"), width = "100%", height="100%"),
                                                                            br(),
                                                                            br(),
                                                                            plotlyOutput(ns("std_stats_DPplot"), width = "100%", height="100%")
                                                                      )
                                                                   
                                                                   
                                                                  ),
                                                          
                                                          
                                                          tabPanel("Intensities",
                                                                   
                                                                   div(style = "max-width: 1000px; width: 100%; max-height: 500px; height: 100%; margin:0 auto;",
                                                                            plotlyOutput(ns("std_stats_areaplot"), width = "100%", height="100%"),
                                                                            br(),
                                                                            br(),
                                                                            plotlyOutput(ns("std_stats_areastdplot"), width = "100%", height="100%"),
                                                                            br(),
                                                                            br(),
                                                                            plotlyOutput(ns("std_stats_SNplot"), width = "100%", height="100%")
                                                                      )
                                                                   
                                                                   
                                                                  )
                                              
                                            )
                                            
                                            
                                            
                                        )
            )

}
