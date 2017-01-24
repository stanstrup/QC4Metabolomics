fluidPage(
    div(style = "max-width: 1000px; width: 100%; max-height: 500px; height: 100%; margin:0 auto;",
    plotlyOutput("std_stats_rtplot", width = "100%", height="100%"),
    
    br(),
    br(),
    
    plotlyOutput("std_stats_mzplot", width = "100%", height="100%")
    )
    
)
