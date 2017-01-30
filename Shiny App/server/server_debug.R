output$wd <- renderPrint({
    getwd()
})


output$sessionInfo <- renderPrint({
    sessionInfo()
})


output$packages_packrat <- renderDataTable(
    datatable({
        installed.packages() %>% unrowname %>% as.data.frame %>% select(Package,LibPath,Version,Built) %>% filter(grepl("packrat/lib/",.$LibPath,fixed = TRUE))
    })
)


output$packages <- renderDataTable(
    datatable({
        installed.packages() %>% unrowname %>% as.data.frame %>% select(Package,LibPath,Version,Built) %>% filter(!grepl("packrat/lib/",.$LibPath,fixed = TRUE))
    })
)
