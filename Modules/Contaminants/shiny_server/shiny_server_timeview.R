dbGetQuery_sel_no_warn <- MetabolomiQCsR:::selectively_suppress_warnings(dbGetQuery, pattern = "unrecognized MySQL field type 7 in column 12 imported as character")


# Build UI for time view --------------------------------------------------
all_ions <- reactive({
                        mode_select    <- input$mode_select_input %>% paste(collapse="','") %>% paste0("('",.,"')")
                        
                        paste0("SELECT cont_cmp.ion_id, cont_cmp.name, cont_cmp.mode, cont_cmp.mz
                                             FROM cont_cmp ",
                               "INNER JOIN (SELECT DISTINCT ion_id, mode FROM cont_data) cont_data
                               ON cont_cmp.ion_id = cont_data.ion_id AND cont_cmp.mode = cont_data.mode ",
                               "WHERE (cont_cmp.mode IN ",mode_select,")"
                                    
                               ) %>% 
                        dbGetQuery_sel_no_warn(pool,.) %>% 
                        as_tibble 
                        
    })


output$cont_select_ui <- renderUI({
        ns <- session$ns

        conts <- all_ions()

        conts %<>% mutate(disp_name = paste0(name," (mz=",round(mz,4),")")) %>%
                   mutate(name_mode = paste0(name," (",mode,")")) %>%
                   mutate(ion_id_mode = paste0(ion_id,"___",mode)) %>%
                   arrange(as.numeric(mz), name) %>% 
                   split(., .$name_mode)

        conts <- lapply(conts, function(y) setNames(y$ion_id_mode, y$disp_name))

        
        selectInput(ns("cont_select"), label = "Contaminant", choices = conts)

})




# Get data ----------------------------------------------------------------

# Get the data available for the selected files and selected contaminant
time_data_selected <-  reactive({

                                 validate(
                                           need(nrow(files_tbl_selected()) != 0, "No data selected. Please check your query.")
                                         )
    
                                     validate(
                                           need(!is.null(input$cont_select) & !(input$cont_select==""), "No ion selected.")
                                         )
    
    
                                metric <- input$time_int %>% as.character
                                
                                
                                md5_str <- files_tbl_selected() %>% extract2("file_md5") %>% paste(collapse="','") %>% paste0("('",.,"')")
                                
                                ion_id <- gsub("^(.*)___.*$","\\1",input$cont_select)
                                mode <-  gsub("^.*___(.*)$","\\1",input$cont_select)
                                

                                out <- paste0("
                                             SELECT cont_data.*, cont_cmp.name, cont_cmp.anno, cont_cmp.notes, file_info.sample_id, file_info.time_run, files.path
                                             FROM cont_data
                                             LEFT JOIN cont_cmp USING(ion_id, mode)
                                             LEFT JOIN file_info USING(file_md5)
                                             LEFT JOIN files USING(file_md5)
                                             WHERE (cont_data.stat = '",metric,"') AND (
                                             cont_cmp.ion_id = '", ion_id,"') AND (
                                             file_md5 IN ",md5_str,")"," AND (
                                             cont_cmp.mode = '", mode,"')"
                                            ) %>% 
                                    dbGetQuery_sel_no_warn(pool,.) %>% 
                                    as_tibble %>% 
                                    mutate(across(time_run, ~as.POSIXct(., tz="UTC"))) %>% 
                                    mutate(time_run = with_tz(time_run, Sys.timezone(location = TRUE))) # time zone fix
                                
                                out
                                })





# PLOT: Time view ------------------------------------------------------
output$time_plot <- renderPlotly({
    
    data <- files_tbl_selected() %>% 
            select(file_md5, time_run, path) %>% 
            left_join(time_data_selected() %>% select(-time_run, -path), by = "file_md5") %>% 
            filter(!is.na(ion_id))
    
    data %<>% mutate(value = ifelse(is.na(value),0, value ))

    ion_name <- all_ions() %>% filter(ion_id == input$cont_select) %>% extract2("name")
    
    timeplot(data, ion_name) %>% timeplot_plotly(data,.)

})

