require(ggplot2)
require(plotly)
require(DBI)
require(magrittr)
require(dplyr)
require(ggthemes)
require(scales)
require(zoo)
require(glue)
require(lubridate)

# functions ---------------------------------------------------------------
std_stats_plot_common <- function(p){ p+
                                      geom_line() +
                                      geom_point(aes(text = paste("Filename:", filename))) +
                                      theme_gdocs() +
                                      theme(axis.title=element_text(face="bold", size = 16), title=element_text(face="bold", size = 18)) +
                                      labs(group="", color="")
                                    }

std_stats_plotmargin_fix <- function(p){
                                            p$x$layout$margin$l <- p$x$layout$margin$l + 30 # avoid cut axis titles
                                            p$x$layout$margin$b <- p$x$layout$margin$b + 10
                                            p$x$layout$legend$y <- 0.9 # legend at the top
                                            
                                            return(p)
                                        }



# Build data range selector -----------------------------------------------
# Get time range available in the db
files_date_range <-    reactive({   default_time_range(min_weeks=2, min_samples = 200, pool = pool)  })



# build the ui
output$file_date_range_ui <- renderUI({
  
  validate(
    need(files_date_range(), "no files found so no time-range could be selected")
    )
    
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
# Get available projects
std_stats_project_available <- reactive({ 
    
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
        as.matrix %>% as.character %>% sort
})



# build the ui
output$std_stats_project_select_ui <- renderUI({
                                                 ns <- session$ns
                                                 
                                                 selectInput(ns("std_stats_project_select_input"), 
                                                               label = "Project", 
                                                               choices  = std_stats_project_available(),
                                                               selected = std_stats_project_available(),
                                                               multiple = TRUE,
                                                               width="100%"
                                                             )

})


# Build mode selector --------------------------------------------------
# Get available modes
std_stats_mode_available <-    reactive({    "
                                                 SELECT DISTINCT mode
                                                 FROM file_info
                                                " %>% 
                                                dbGetQuery(pool,.) %>% 
                                                as.matrix %>% as.character
                                           })


# build the ui
output$std_stats_mode_select_ui <- renderUI({
                                                 ns <- session$ns
                                                 
                                                 selectInput(ns("std_stats_mode_select_input"), 
                                                               label = "Mode", 
                                                               choices  = std_stats_mode_available(),
                                                               selected = std_stats_mode_available(),
                                                               multiple = TRUE
                                                             )

})



# Reset button ------------------------------------------------------------
observeEvent(input$std_stats_resetButton,{
             
             updateSelectInput(session,
                               inputId  = "std_stats_project_select_input",
                               choices  = std_stats_project_available(),
                               selected = std_stats_project_available()
                             )
    
             updateSelectInput(session,
                               inputId  = "std_stats_mode_select_input",
                               choices  = std_stats_mode_available(),
                               selected = std_stats_mode_available()
                         )
    
             updateDateRangeInput(session,
                                  inputId = "file_date_range_input",
                                  start = files_date_range()["min"] %>% as.Date %>% as.character %>% unname, 
                                  end   = files_date_range()["max"] %>% as.Date %>% as.character %>% unname, 
                                  min   = files_date_range()["min"] %>% as.Date %>% as.character %>% unname,
                                  max   = files_date_range()["max"] %>% as.Date %>% as.character %>% unname
                                  )
             
             
             updateTextInput(session,
                             inputId = "std_stats_sample_id",
                             value = ""
                             )
            
             updateCheckboxInput(session,
                             inputId = "std_stats_sample_id_inv",
                             value = FALSE
                             )
             
             }
             )


# Get all data in selected range ------------------------------------------

# Get sample ID search string and make it slower to react/update/invalidate
std_stats_sample_id_reactive <- reactive(input$std_stats_sample_id) %>% 
                                debounce(2*1000)



# Get the files in selected range
std_data_selected <- reactive({

  validate(
    need(input$std_stats_project_select_input, "No project(s) selected or not retrived yet. Please check your query."),
    need(input$std_stats_mode_select_input, "No mode(s) selected or not retrived yet. Please check your query."),
    need(!is.null(input$std_stats_sample_id_inv), "No reverse search selection received yet. Hold on."),
    need(!is.null(input$std_stats_sample_id), "No search string received yet. Hold on."),
    need(global_instruments_input(), "Haven't retrieved list of instruments yet. Hold on.")
  )
  
    project_select <- input$std_stats_project_select_input %>% paste(collapse="','") %>% paste0("('",.,"')")
    mode_select    <- input$std_stats_mode_select_input %>% paste(collapse="','") %>% paste0("('",.,"')")
    REGEXP <- std_stats_sample_id_reactive() %>% ifelse(.=="",".*",.)
    REGEXP_inv <- input$std_stats_sample_id_inv %>% ifelse("NOT ", "")
    instrument_select <- global_instruments_input() %>% paste(collapse="','") %>% paste0("('",.,"')")
    
    out <- glue("
      SELECT file_info.mode, file_info.time_run, files.path, std_stat_data.*, std_stat_types.stat_name, std_compounds.cmp_name, std_compounds.cmp_mz, std_compounds.cmp_rt1, std_compounds.updated_at
      FROM file_info CROSS JOIN std_stat_types
      
      LEFT JOIN files ON (file_info.file_md5 = files.file_md5)
      LEFT JOIN std_stat_data ON (file_info.file_md5 = std_stat_data.file_md5) AND (std_stat_types.stat_id = std_stat_data.stat_id)
      LEFT JOIN std_compounds ON (std_compounds.cmp_id = std_stat_data.cmp_id)
      
      WHERE (file_info.sample_id '{REGEXP_inv}' REGEXP '{REGEXP}')
      AND (DATE(file_info.time_run) BETWEEN '{input$file_date_range_input[1]}' AND '{input$file_date_range_input[2]}')
      AND (file_info.project in {project_select})
      AND (file_info.mode in {mode_select})
      AND (file_info.instrument in {instrument_select})
      AND std_stat_types.stat_name in ('TF', 'ASF', 'datapoints', 'into', 'sn', 'rt_dev', 'mz_dev_ppm', 'FWHM')
      ;
      "
      ) %>% 
       dbGetQuery(pool,.) %>% 
       as_tibble %>% 
      mutate(across(c(updated_at, time_run), ~as.POSIXct(., tz="UTC", format="%Y-%m-%d %H:%M:%S"))) %>% 
      mutate(time_run = with_tz(time_run, Sys.timezone(location = TRUE))) %>% # time zone fix
      mutate(filename = sub('\\..*$', '', basename(path)))


  validate(
    need(nrow(out) != 0, "No data selected. Please check your query.")
  )
  
  out
  
})




# PLOT: Retention time deviation------------------------------------------------
output$std_stats_rtplot <- renderPlotly({
  
    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("rt_dev")) %>%
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "Retention time deviation (min)", x = "Run time") +
                                ggtitle("Retention time deviation")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})


# PLOT: mz deviation ------------------------------------------------
output$std_stats_mzplot <- renderPlotly({

    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("mz_dev_ppm")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "<i>m/z</i> deviation (ppm)", x = "Run time") +
                                ggtitle("<i>m/z</i> deviation")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})



# PLOT: Full Width at Half Maximum (FWHM) ---------------------------------
output$std_stats_fwhmplot <- renderPlotly({

    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("FWHM")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "FWHM (min)", x = "Run time") +
                                ggtitle("Full Width at Half Maximum (FWHM)")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})




# PLOT: Tailing Factor -----------------------------------
output$std_stats_TFplot <- renderPlotly({

    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("TF")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "Tailing Factor", x = "Run time") +
                                ggtitle("Tailing Factor")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})


# PLOT: Asymmetry Factor ---------------------------------
output$std_stats_AFplot <- renderPlotly({

    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("ASF")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "Asymmetry Factor", x = "Run time") +
                                ggtitle("Asymmetry Factor")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})


# PLOT: # data points ---------------------------------
output$std_stats_DPplot <- renderPlotly({

    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("datapoints")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "# Data points", x = "Run time") +
                                ggtitle("Data points")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})


# PLOT: # area ---------------------------------
output$std_stats_areaplot <- renderPlotly({

    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("into")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "Area", x = "Run time") +
                                ggtitle("Area")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})



# PLOT: # Area STD ---------------------------------
output$std_stats_areastdplot <- renderPlotly({

      p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("into")) %>% 
                                arrange(time_run) %>% 
                                group_by(cmp_name) %>% 
                                mutate(value = rollapplyr(value, FUN = sd, width=5, fill=NA) / rollapplyr(value, FUN = mean, width=5, fill=NA)) %>% 
                                mutate(value = value*100) %>% 
                                ungroup %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "Area %RSD (5 samples rolling)", x = "Run time") +
                                ggtitle("Area std (5 preceding samples rolling)") +
                                scale_y_continuous(labels = percent)} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})

                                


# PLOT: # S/N ---------------------------------
output$std_stats_SNplot <- renderPlotly({

    p <- std_data_selected() %>% 
                                filter(stat_id == stat_name2id("sn")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "S/N", x = "Run time") +
                                ggtitle("Signal to noise ratio")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    std_stats_plotmargin_fix(p) %>% print
    
})
