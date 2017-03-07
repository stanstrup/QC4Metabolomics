tabPanel("Standard compounds",
                                
                                fluidPage(
                                  #use shiny js to disable the ID field
                                  useShinyjs(),
                                  
                                  # more width on the table
                                  tags$head(
                                    tags$style(type="text/css", paste0("#",ns("std_cmp_tbl")," { max-width: 1200px; }"))
                                  ),
                                
                                  
                                  #data table
                                  dataTableOutput(ns("std_cmp_tbl")), 
                                  
                                  #input fields
                                  tags$hr(),
                                  
                                  div(
                                        div( style="display: inline-block;",
                                             disabled(numericInput(ns("std_cmp_id"), "Id", NULL))
                                           ),
                                        div( style="display: inline-block;",
                                             textInput(   ns("std_cmp_name"),     "Compound name", "")
                                           )
                                    ),
                                  
                                  
                                    div(
                                        div( style="display: inline-block;vertical-align: top;",
                                             selectInput( ns("std_cmp_mode"),     "Mode", c("","pos","neg"), "")
                                           ),
                                        div( style="display: inline-block;vertical-align: top;",
                                             numericInput(ns("std_cmp_mz"),       "m/z", NULL, step=0.0001)
                                           )
                                    ),
                                  
                                  
                                      div(
                                        div( style="display: inline-block;vertical-align: top;",
                                             numericInput(ns("std_cmp_rt1"),      "rt1 (min)", NULL, step=0.01)
                                           ),
                                        div( style="display: inline-block;vertical-align: top;",
                                             numericInput(ns("std_cmp_rt2"),      "rt2 (min)", NULL, step=0.01)
                                           )
                                    ),
                                  
                                  
                                  
                                  checkboxInput(ns("std_cmp_enable"), "Enable", TRUE),
                                  
                                  
                                  #action buttons
                                  actionButton(ns("std_cmp_submit"), "Submit"),
                                  actionButton(ns("std_cmp_new"), "New"),
                                  actionButton(ns("std_cmp_delete"), "Delete")
                                )
                                

)
