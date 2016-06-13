library(DT)
library(plyr)
library(dplyr)

shinyUI(           navbarPage("Navigation bar",
                                          tabPanel("Overview"),
                              
                              navbarMenu("More",
                                         tabPanel("Debug",
                                                  source("ui/ui_debug.R", local=TRUE)$value
                                         )
                              )
                             )
        
                   
        )
