tabPanel("Warning rules",
                                
                                fluidPage(
                                  #use shiny js to disable the ID field
                                  useShinyjs(),
                                  
                                  # more width on the table
                                  tags$head(
                                    tags$style(type="text/css", paste0("#",ns("warner_tbl")," { max-width: 1200px; }"))
                                  ),
                                
                                  
                                  #data table
                                  dataTableOutput(ns("warner_tbl")), 
                                  
                                  #input fields
                                  tags$hr(),
                                  
                                  div(
                                        div( style="display: inline-block;",
                                             disabled(numericInput(ns("warner_rule_id"), "Id", NULL))
                                           ),
                                        div( style="display: inline-block;",
                                             textInput(   ns("warner_rule_name"),     "Rule name", "")
                                           )
                                    ),
                                  
                                  
                                    div(
                                        div( style="display: inline-block;vertical-align: top;",
                                             textInput( ns("warner_instrument"),     "Instrument", "")
                                           )
                                       ),
                                  
                                  div(
                                      div( style="display: inline-block;vertical-align: top;",
                                           uiOutput(ns("warner_stat_ui"))
                                         ),
                                      div( style="display: inline-block;vertical-align: top;",
                                           selectInput( ns("warner_operator"),     "Operator", c("<",">","="), "")
                                         ),
                                      div( style="display: inline-block;vertical-align: top;",
                                           numericInput(ns("warner_value"),       "value", NULL, step=0.0001)
                                         ),
                                      div( style="display: inline-block;vertical-align: bottom;",
                                           tags$div(
                                             tags$label("Use absolute value"),
                                             checkboxInput(ns("warner_use_abs"), "", value = TRUE)
                                           )
                                      )
                                     ),

     
                                  
                                  checkboxInput(ns("warner_enable"), "Enable", TRUE),
                                  
                                  
                                  #action buttons
                                  actionButton(ns("warner_submit"), "Submit"),
                                  actionButton(ns("warner_new"), "New"),
                                  actionButton(ns("warner_delete"), "Delete")
                                )
                                

)
