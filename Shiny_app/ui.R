
shinyUI(           navbarPage("Navigation bar",
                                          tabPanel("Overview"),
                              
                              navbarMenu("More",
                                         tabPanel("Debug",
                                                  source("ui/ui_debug.R", local=TRUE)$value
                                                 ),
                                         
                                         tabPanel("Log",
                                                  source("ui/ui_log.R", local=TRUE)$value
                                                 )
                                         
                                         )
                              
                              
                              
                              
                             )
        
                   
        )
