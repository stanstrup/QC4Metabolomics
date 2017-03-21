require(ggplot2)
require(plotly)
require(DBI)
require(magrittr)
require(dplyr)
require(ggthemes)
require(scales)
require(zoo)

# functions ---------------------------------------------------------------
plotmargin_fix <- function(p){
                                            p$x$layout$margin$l <- p$x$layout$margin$l + 30 # avoid cut axis titles
                                            p$x$layout$margin$b <- p$x$layout$margin$b + 10
                                            p$x$layout$legend$y <- 0.9 # legend at the top
                                            
                                            return(p)
                                        }



# Build data range selector -----------------------------------------------
# Get time range available in the db
files_date_range <-    reactive({
                                    "
                                     SELECT 
                                     MIN(time_run) AS min,
                                     MAX(time_run) AS max
                                     FROM file_info
                                    " %>% 
                                    dbGetQuery(pool,.) %>% 
                                    {setNames(as.POSIXct(as.character(.),format= "%Y-%m-%d %H:%M:%S"), names(.))}
                                    
                               })

# build the ui
output$file_date_range_ui <- renderUI({
    
                                        ns <- session$ns
                                        
                                        dateRangeInput(ns("file_date_range_input"), 
                                                       label = "Date range", 
                                                       start = files_date_range()["min"] %>% as.Date %>% as.character, 
                                                       end   = files_date_range()["max"] %>% as.Date %>% as.character, 
                                                       min   = files_date_range()["min"] %>% as.Date %>% as.character,
                                                       max   = files_date_range()["max"] %>% as.Date %>% as.character, 
                                                       weekstart = 1
                                                       )
})




# Build project selector --------------------------------------------------
# Get avaiable projects
project_available <-    reactive({    "
                                                 SELECT DISTINCT project
                                                 FROM file_info
                                                " %>% 
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
                                                               multiple = TRUE
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


# Get all data in selected range ------------------------------------------

# Get sample ID search string and make it slower to react/update/invalidate
sample_id_reactive <- reactive(input$sample_id) %>% 
                                debounce(2*1000)



# Get the files in selected range
files_tbl_selected <- reactive({

                                    project_select <- input$project_select_input %>% paste(collapse="','") %>% paste0("('",.,"')")
                                    mode_select    <- input$mode_select_input %>% paste(collapse="','") %>% paste0("('",.,"')")
                                    REGEXP <- sample_id_reactive() %>% ifelse(.=="",".*",.)
                                    REGEXP_inv <- input$sample_id_inv %>% ifelse("NOT ", "")
                                    
                                    paste0(
                                    "SELECT * FROM file_info ",
                                    "WHERE ",
                                    "(sample_id ",REGEXP_inv,"REGEXP ","'",REGEXP,"') AND ",
                                    "(DATE(time_run) BETWEEN '",input$file_date_range_input[1],"' AND '",input$file_date_range_input[2],"') AND ",
                                    "(project in ",project_select,") AND ",
                                    "(mode in ",mode_select,")"
                                    
                                    ) %>% 
                                    dbGetQuery(pool,.) %>% as.tbl
                               })



# Get all the data available for the selected files
std_data_selected <-  reactive({
    
                                      validate(
                                                need(nrow(files_tbl_selected()) != 0, "No data selected. Please check your query.")
                                                )
    
    
                                     files_tbl_selected() %>% 
                                     extract2("file_md5") %>% 
                                     paste(collapse="','") %>% 
                                     paste0("'",.,"'") %>% 
                                     paste0(
                                             "SELECT time_run, project FROM file_info",
                                             " WHERE file_md5 in (",.,")
                                            ") %>% 
                                     dbGetQuery(pool,.) %>% 
                                     as.tbl %>% 
                                    mutate_each(funs(as.POSIXct(., tz="UTC", format="%Y-%m-%d %H:%M:%S")), time_run)
                                })



# PLOT: heatmap -----------------------------------------------------------
# output$heatmap <- renderPlotly({
#     if(!(nrow(std_data_selected())>0)) return(NULL)
# 
#     calendar <- std_data_selected() %>% extract2("time_run") %>%
#                             year %>%
#                             {c(min = paste0(min(.),"-01-01"), max = paste0(max(.),"-12-31"))} %>%
#                             as.Date %>%
#                             {seq(from = min(.), to = max(.), by = "day")} %>%
#                             data_frame(date = .) %>%
#                             mutate(yday = yday(date), week = isoweek(date), wday =  wday(date, label=TRUE), year =  isoyear(date), month = month(date, label = TRUE)) %>%
#                             mutate(wday = ordered(wday, levels=c("Mon","Tues","Wed","Thurs","Fri","Sat","Sun"))) %>%
#                             group_by(year, week) %>%
#                             mutate(mon_month = month[1]) %>%
#                             ungroup
# 
# 
# 
#     plot_data <- std_data_selected() %>%
#                     select(time_run, project) %>%
#                     mutate(year = isoyear(time_run), yday = yday(time_run)) %>%
#                     group_by(year, yday) %>%
#                     summarise(`Samples #` = n(), project = paste(unique(project),collapse="/")) %>%
#                     ungroup %>%
#                     right_join(calendar, by = c("year", "yday")) %>%
#                     filter(year==2016)
# 
# 
# 
#     # make nice color scale
#     color_scale <- viridis(256, option = "plasma")
#     colfunc <- colorRampPalette(c(last(color_scale), "white"))
#     color_scale <- rev(c(color_scale,colfunc(20)))
# 
# 
#     p <- ggplot(data = plot_data, aes(x = wday, y = week, fill = `Samples #`, text = paste0("Date: ", date))) +
#     geom_tile() +
#     geom_text(aes(label=project), color="green") +
#     scale_fill_gradientn(colours = color_scale, na.value="transparent", limits = c(0,NA)) +
#     theme_gdocs() +
#     theme(axis.title=element_text(face="bold", size = 16), title=element_text(face="bold", size = 18)) +
#     scale_x_discrete(drop=FALSE) +
#     scale_y_continuous(breaks = 1:52, trans="reverse") +
#     facet_grid(mon_month~.,drop=T,space="free",scales="free") +
#     theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
#     labs(x = "Day", y = "Week") +
#     theme(strip.text = element_text(size=9, lineheight=3)) +
#     theme(panel.border = element_rect(colour = "black")) +
#     theme(strip.background = element_rect(colour=NA, fill=NA)) +
#     theme(panel.spacing = unit(0, "lines"))
# 
# 
#     pp <- plotly_build(p)
# 
#     t_rep <- c("`Samples #`: 0", "week: ", "Samples #")
#     names(t_rep) <- c("`Samples #`: NA", "week: -","`Samples #`")
#     pp <- plotly_clean_tt(pp, rep=t_rep)
# 
#     plotmargin_fix(pp) %>% print
# 
# 
# })



# PLOT: All heatmaps ------------------------------------------------------

get_plot_output_list <- function(years, data, nss) {
  # Insert plot output objects the list
  plot_output_list <- lapply(years, function(i) {
                                                    
                                                    plotname <- paste("plot", i, sep="")
                                                    plot_output_object <- plotlyOutput(plotname, width = "1400px", height="900px")
                                                    
                                                    plot_output_object <- renderPlotly({
                                                        
                                                                                            if(!(nrow(data)>0)) return(NULL)
                                                                                            
                                                                                            calendar <- data %>% extract2("time_run") %>% 
                                                                                                                    year %>% 
                                                                                                                    {c(min = paste0(min(.),"-01-01"), max = paste0(max(.),"-12-31"))} %>%
                                                                                                                    as.Date %>% 
                                                                                                                    {seq(from = min(.), to = max(.), by = "day")} %>% 
                                                                                                                    data_frame(date = .) %>% 
                                                                                                                    mutate(yday = yday(date), week = isoweek(date), wday =  wday(date, label=TRUE), year =  isoyear(date), month = month(date, label = TRUE)) %>% 
                                                                                                                    mutate(wday = ordered(wday, levels=c("Mon","Tues","Wed","Thurs","Fri","Sat","Sun"))) %>% 
                                                                                                                    group_by(year, week) %>%
                                                                                                                    mutate(mon_month = month[1]) %>% 
                                                                                                                    ungroup
                                                                                            
                                                                                            
                                                                                            
                                                                                            plot_data <- data %>% 
                                                                                                            select(time_run, project) %>% 
                                                                                                            mutate(year = isoyear(time_run), yday = yday(time_run)) %>% 
                                                                                                            group_by(year, yday) %>% 
                                                                                                            summarise(`Samples #` = n(), project = paste(unique(project),collapse="/")) %>% 
                                                                                                            ungroup %>% 
                                                                                                            right_join(calendar, by = c("year", "yday")) %>%
                                                                                                            filter(year==i)
                                                                                            
                                                                                            
                                                                                            
                                                                                            # make nice color scale
                                                                                            color_scale <- viridis(256, option = "plasma")
                                                                                            colfunc <- colorRampPalette(c(last(color_scale), "white"))
                                                                                            color_scale <- rev(c(color_scale,colfunc(20)))
                                                                                            
                                                                                            
                                                                                            p <- ggplot(data = plot_data, aes(x = wday, y = week, fill = `Samples #`, text = paste0("Date: ", date))) +
                                                                                            geom_tile() +
                                                                                            geom_text(aes(label=project), color="green") +
                                                                                            scale_fill_gradientn(colours = color_scale, na.value="transparent", limits = c(0,NA)) +
                                                                                            theme_gdocs() +
                                                                                            theme(axis.title=element_text(face="bold", size = 16), title=element_text(face="bold", size = 18)) +
                                                                                            scale_x_discrete(drop=FALSE) +
                                                                                            scale_y_continuous(breaks = 1:52, trans="reverse") +
                                                                                            facet_grid(mon_month~.,drop=T,space="free",scales="free") +
                                                                                            theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
                                                                                            labs(x = "Day", y = "Week") +
                                                                                            theme(strip.text = element_text(size=9, lineheight=3)) +
                                                                                            theme(panel.border = element_rect(colour = "black")) +
                                                                                            theme(strip.background = element_rect(colour=NA, fill=NA)) +
                                                                                            theme(panel.spacing = unit(0, "lines"))
                                                                                            
                                                                                            
                                                                                            pp <- plotly_build(p)
                                                                                            
                                                                                            t_rep <- c("`Samples #`: 0", "week: ", "Samples #")
                                                                                            names(t_rep) <- c("`Samples #`: NA", "week: -","`Samples #`")
                                                                                            pp <- plotly_clean_tt(pp, rep=t_rep)
                                                                                            
                                                                                            plotmargin_fix(pp) %>% print
                                                        
                                                        
                                                    })
    
    
                                                }
                            )

  do.call(tagList, plot_output_list) # needed to display properly.

}





  observe({
    
    ns <- session$ns
    output$heatmaps <- renderUI({   std_data_selected() %>% 
                                    extract2("time_run") %>% 
                                    year %>% unique %>% 
                                    get_plot_output_list(years = ., data = std_data_selected(), ns=ns)
                                })
  })
