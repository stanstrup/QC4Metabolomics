Debug <- function(input, output, session, global_instruments_input){
    require(DT)
    require(dplyr)

    output$wd <- renderPrint( getwd() )


    output$sessionInfo <- renderPrint( sessionInfo() )


    output$packages_packrat <- renderDataTable(
                                                datatable({
                                                    installed.packages() %>%
                                                                            as.data.frame(row.names = NULL) %>%
                                                                            select(Package,LibPath,Version,Built) %>%
                                                                            filter(grepl("renv/library/",.$LibPath,fixed = TRUE))
                                                         })
                                              )


    output$packages <- renderDataTable(
                                        datatable({
                                                    installed.packages() %>%
                                                                            as.data.frame(row.names = NULL) %>%
                                                                            select(Package,LibPath,Version,Built) %>%
                                                                            filter(!grepl("renv/library/",.$LibPath,fixed = TRUE))
                                                  })
                                      )

}
