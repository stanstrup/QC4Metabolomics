# Build data range selector -----------------------------------------------
# Get time range available in the db
files_date_range <-    reactive({   default_time_range(min_weeks=6*4, min_samples = 500, pool = pool)  })

# build the ui
output$file_date_range_ui <- renderUI({
    
                                        ns <- session$ns
                                        
                                        dateRangeInput(ns("file_date_range_input"), 
                                                       label = "Date range", 
                                                       start = files_date_range()["min"] %>% as.Date %>% as.character, 
                                                       end   = files_date_range()["max"] %>% as.Date %>% as.character, 
                                                       min   = "1970-01-01",
                                                       max   = files_date_range()["max"] %>% as.Date %>% as.character, 
                                                       weekstart = 1
                                                       )
})




# Build project selector --------------------------------------------------
# Get avaiable projects
project_available <- reactive({ 
    
    global_instruments_input() %>%
        paste(collapse="','") %>% 
        paste0("'",.,"'") %>% 
        paste0("
                SELECT DISTINCT project
                FROM file_info
                WHERE instrument IN (
               ",
               .,
               ")"
        ) %>% 
        dbGetQuery(pool,.) %>% 
        as.matrix %>% as.character
})


# build the ui
output$project_select_ui <- renderUI({
                                                 ns <- session$ns
                                                 
                                                 selectInput(ns("project_select_input"), 
                                                               label = "Project", 
                                                               choices  = project_available(),
                                                               selected = project_available(),
                                                               multiple = TRUE,
                                                               width="100%"
                                                             )

})


# Build mode selector --------------------------------------------------
# Get avaiable modes
mode_available <-    reactive({    "
                                                 SELECT DISTINCT mode
                                                 FROM file_info
                                                " %>% 
                                                dbGetQuery(pool,.) %>% 
                                                as.matrix %>% as.character
                                           })


# build the ui
output$mode_select_ui <- renderUI({
                                                 ns <- session$ns
                                                 
                                                 selectInput(ns("mode_select_input"), 
                                                               label = "Mode", 
                                                               choices  = mode_available(),
                                                               selected = mode_available(),
                                                               multiple = TRUE
                                                             )

})



# Reset button ------------------------------------------------------------
observeEvent(input$resetButton,{
             
             updateSelectInput(session,
                               inputId  = "project_select_input",
                               choices  = project_available(),
                               selected = project_available()
                             )
    
             updateSelectInput(session,
                               inputId  = "mode_select_input",
                               choices  = mode_available(),
                               selected = mode_available()
                         )
    
             updateDateRangeInput(session,
                                  inputId = "file_date_range_input",
                                  start = files_date_range()["min"] %>% as.Date %>% as.character %>% unname, 
                                  end   = files_date_range()["max"] %>% as.Date %>% as.character %>% unname, 
                                  min   = files_date_range()["min"] %>% as.Date %>% as.character %>% unname,
                                  max   = files_date_range()["max"] %>% as.Date %>% as.character %>% unname
                                  )
             
             
             updateTextInput(session,
                             inputId = "sample_id",
                             value = ""
                             )
            
             updateCheckboxInput(session,
                             inputId = "sample_id_inv",
                             value = FALSE
                             )
             
             }
             )




# Get selected files ------------------------------------------------------

# Get sample ID search string and make it slower to react/update/invalidate
sample_id_reactive <- reactive(input$sample_id) %>% 
                                debounce(2*1000)



# Get the files in selected range
files_tbl_selected <- reactive({

                                    project_select <- input$project_select_input %>% paste(collapse="','") %>% paste0("('",.,"')")
                                    mode_select    <- input$mode_select_input %>% paste(collapse="','") %>% paste0("('",.,"')")
                                    REGEXP <- sample_id_reactive() %>% ifelse(.=="",".*",.)
                                    REGEXP_inv <- input$sample_id_inv %>% ifelse("NOT ", "")
									instrument_select <- global_instruments_input() %>% paste(collapse="','") %>% paste0("('",.,"')")
                                    
                                    paste0(
                                    "SELECT file_info.file_md5, file_info.time_run, files.path FROM file_info ",
                                    "LEFT JOIN files USING(file_md5) ",
                                    "WHERE ",
                                    "(sample_id ",REGEXP_inv,"REGEXP ","'",REGEXP,"') AND ",
                                    "(DATE(time_run) BETWEEN '",input$file_date_range_input[1],"' AND '",input$file_date_range_input[2],"') AND ",
                                    "(project in ",project_select,") AND ",
                                    "(mode in ",mode_select,") AND",
                                    "(instrument in ",instrument_select,")"                                    
                                    ) %>% 
                                    dbGetQuery(pool,.) %>% as_tibble %>% 
                                    mutate(across(time_run, ~as.POSIXct(., tz="UTC")))
                               })

