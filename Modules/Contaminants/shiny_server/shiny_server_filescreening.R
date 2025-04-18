dbGetQuery_sel_no_warn <- MetabolomiQCsR:::selectively_suppress_warnings(dbGetQuery, pattern = "unrecognized MySQL field type 7 in column 12 imported as character")


# Build UI for file screening --------------------------------------------------
output$file_select_ui <- renderUI({
        ns <- session$ns
        
        files <- setNames(files_tbl_selected() %>% extract2("file_md5"), files_tbl_selected() %>% extract2("path") %>% {sub('\\..*$', '', basename(.))} )

        selectInput(ns("file_select"), label = "Select file", choices = files)

})




# Get data ----------------------------------------------------------------


# Get the data available for the selected file
file_screening_selected <-  reactive({

                                 validate(
                                           need(!is.null(input$file_select) & !(input$file_select==""), "No file selected.")
                                         )
    

                                metric <- input$file_int %>% as.character
                                
                                
                                md5_str <- files_tbl_selected() %>% extract2("file_md5") %>% paste(collapse="','") %>% paste0("('",.,"')")
                                

                                out <- paste0("
                                             SELECT cont_data.*, cont_cmp.name,cont_cmp.mz, cont_cmp.anno, cont_cmp.notes, file_info.sample_id, file_info.time_run
                                             FROM cont_data
                                             LEFT JOIN cont_cmp USING(ion_id, mode)
                                             LEFT JOIN file_info USING(file_md5)
                                             WHERE (cont_data.stat = '",metric,"') AND (
                                             file_md5 = '", input$file_select,"')"

                                            ) %>% 
                                    dbGetQuery_sel_no_warn(pool,.) %>% 
                                    as_tibble %>% 
                                    mutate(across(time_run, ~as.POSIXct(., tz="UTC")))
                                
                                out
                                })






# PLOT: File screening ------------------------------------------------------
output$file_screen_plot <- renderPlotly({
    
req(input$file_select)
  
    title <-    files_tbl_selected() %>%
                filter(file_md5 == input$file_select) %>%
                distinct %>%
                extract2("path") %>%
                {sub('\\..*$', '', basename(.))}
        
    file_screening_selected() %>% 
                                    mutate(comp_name = paste0(name," (",anno,", ", round(mz,4),")")) %>%    
                                    plot_contaminants(data = ., 
                                                      title = title,
                                                      x_var = "comp_name", 
                                                      y_var = "value",
                                                      y_lab = switch(input$file_int,EIC_mean = "Mean EIC", EIC_median = "Median EIC", EIC_max = "Max EIC")
                                                      ) %>% 
                                    plotly_clean_tt(rep=c(`comp_name:` = "<b>Compound:</b>", `value:` = "<b>EIC Median:</b>")) 
})

