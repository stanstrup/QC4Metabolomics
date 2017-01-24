
shinyServer(function(input, output, session) {
    
    
    # Tabs --------------------------------------------------------------------
    source("server/server_debug.R",local=TRUE)
    source("server/server_log.R",local=TRUE)
    source("server/server_std_cmp.R",local=TRUE)
    source("server/server_std_stats.R",local=TRUE)
    
})
