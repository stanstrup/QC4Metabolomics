fluidPage(
    

    h4("Working directory"),
    verbatimTextOutput("wd"),
    
    br(),
    
    h4("Session Info"),
    verbatimTextOutput("sessionInfo"),
    
    br(),
    
    h4("Installed packages in packrat"),
    dataTableOutput("packages_packrat"),
    
    br(),
    
    h4("Installed packages NOT in packrat"),
    dataTableOutput("packages")
)
