Log <- function(input, output, session, global_instruments_input){

    require(DBI)
    require(DT)
    require(dplyr)
    
    
    log_data <- reactivePoll(10*1000,
                             session=session,
                             function() "SELECT COUNT(*) FROM log"                       %>% dbGetQuery(pool, .) %>% as.numeric  ,
                             function() "SELECT * FROM log ORDER BY time DESC LIMIT 100" %>% dbGetQuery(pool, .)
                             )
    

    # Get log from database
      output$log_tbl <- renderDataTable(
          
                                          log_data() %>% 
                                              select(-id) %>% 
                                              rename(message=msg, category=cat) %>% 
                                              datatable(filter="top", selection="none", rownames = FALSE)
          
                                        )

}
