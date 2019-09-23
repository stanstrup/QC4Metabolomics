Debug <- function(input, output, session, global_instruments_input){
    require(DT)
    require(plyr)
    require(dplyr)

    output$wd <- renderPrint( getwd() )
    
    
    output$sessionInfo <- renderPrint( sessionInfo() )
    
    
    output$packages_packrat <- renderDataTable(
                                                datatable({
                                                    installed.packages() %>% 
                                                                            unrowname %>% 
                                                                            as.data.frame %>% 
                                                                            select(Package,LibPath,Version,Built) %>% 
                                                                            filter(grepl("packrat/lib/",.$LibPath,fixed = TRUE))
                                                         })
                                              )
    
    
    output$packages <- renderDataTable(
                                        datatable({
                                                    installed.packages() %>% 
                                                                            unrowname %>% 
                                                                            as.data.frame %>% 
                                                                            select(Package,LibPath,Version,Built) %>% 
                                                                            filter(!grepl("packrat/lib/",.$LibPath,fixed = TRUE))
                                                  })
                                      )

}
