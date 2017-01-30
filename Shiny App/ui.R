
shinyUI(           navbarPage("Navigation bar",
                                          tabPanel("Overview"),
                                          tabPanel("Standard compounds", source("ui/ui_std_cmp.R", local=TRUE)$value),
                              
                                          tabPanel("Standard stats",   source("ui/ui_std_stats.R", local=TRUE)$value ),
                              
                                          navbarMenu("More",
                                                     tabPanel("Debug",   source("ui/ui_debug.R", local=TRUE)$value ),
                                                     
                                                     tabPanel("Log",     source("ui/ui_log.R", local=TRUE)$value   )
                                                     
                                                     )
                                          
                              
                              
                             )
        
                   
        )
