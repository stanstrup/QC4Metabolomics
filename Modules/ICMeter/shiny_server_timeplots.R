require(ggplot2)
require(plotly)
require(DBI)
require(magrittr)
require(dplyr)
require(ggthemes)
require(scales)
require(zoo)
require(lubridate)
require(viridis)


# functions ---------------------------------------------------------------
plotmargin_fix <- function(p){
                                            p$x$layout$margin$l <- p$x$layout$margin$l + 30 # avoid cut axis titles
                                            p$x$layout$margin$b <- p$x$layout$margin$b + 10
                                            p$x$layout$legend$y <- 0.9 # legend at the top
                                            
                                            return(p)
                                        }



# Build data range selector -----------------------------------------------
# Get time range available in the db
date_range <-         reactive({
                                    "
                                     SELECT 
                                     MIN(time) AS min,
                                     MAX(time) AS max
                                     FROM ic_data
                                    " %>% 
                                    dbGetQuery(pool,.) %>% 
                                    {setNames(as.POSIXct(as.character(.),format= "%Y-%m-%d %H:%M:%S"), names(.))}
                                    
                               })

# build the ui
output$file_date_range_ui <- renderUI({
    
                                        ns <- session$ns
                                        
                                        dateRangeInput(ns("file_date_range_input"), 
                                                       label = "Date range", 
                                                       start = {date_range()["max"] - months(1)} %>% as.Date %>% as.character, 
                                                       end   = date_range()["max"] %>% as.Date %>% as.character, 
                                                       min   = date_range()["min"] %>% as.Date %>% as.character,
                                                       max   = date_range()["max"] %>% as.Date %>% as.character, 
                                                       weekstart = 1
                                                       )
})



# Get all data in selected range ------------------------------------------

# Get sample ID search string and make it slower to react/update/invalidate
sample_id_reactive <- reactive(input$sample_id) %>% 
                                debounce(2*1000)




# Get the files in selected range
data_selected <-      reactive({

                                    out <- paste0(
                                                    "SELECT * FROM ic_data ",
                                                    "WHERE ",
                                                    "(DATE(time) BETWEEN '",input$file_date_range_input[1],"' AND '",input$file_date_range_input[2],"')"
                                                    ) %>% 
                                           dbGetQuery(pool,.) %>% as_tibble
    
                                    Encoding(out$metric) <- "UTF-8"
                                    
                                    out
                               })





# PLOT: All time plots ------------------------------------------------------
  output$timeplots <- renderUI({
    device <- data_selected() %>% extract2("device") %>% unique %>% sort(decreasing = TRUE)
     
    plot_output_list <- lapply(device, function(i) {
                                                  ns <- session$ns
                                                  plotname <- ns(paste("plot", i, sep=""))
                                                  plotlyOutput(plotname, width = "1400px", height="900px")
                                                  
                                                  }
                            )

    
    headings <- lapply(device, function(i) { div(style="padding-top: 5em;") } )

    out <- vector(class(plot_output_list), length(plot_output_list)+length(headings))
    out[c(TRUE, FALSE)] <- headings
    out[c(FALSE, TRUE)] <- plot_output_list

    do.call(tagList, out)
  })



  observe({             
    data <- data_selected()
    device <- data %>% extract2("device") %>% unique %>% sort(decreasing = TRUE)
          
    for (i in device) {
                      local({ 
                                
                                my_i <- i
                                plotname <- paste("plot", my_i, sep="")
                                output[[plotname]] <- renderPlotly({
                                                                    if(!(nrow(data)>0)) return(NULL)
                                    
                                                                   
                    
                                                                    plot_data <- data %>%
                                                                                 filter(device==my_i) %>% 
                                                                                 mutate_at(vars(time), ~as.POSIXct(strptime(.,"%Y-%m-%d %H:%M:%S", tz="UTC")))
                                                                    
                                                                    if(nrow(plot_data)==0) return(NULL)
                                                                    
                                                                    p <- ggplot(plot_data, aes(x = time, y = value)) +
                                                                         geom_line(size=0.3) +
                                                                         facet_wrap(~metric, scales="free_y", ncol=1)+
                                                                         theme_gdocs() +
                                                                         theme(axis.title=element_text(face="bold", size = 16), title=element_text(face="bold", size = 18)) +
                                                                         theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
                                                                         theme(strip.text = element_text(size=9, lineheight=3)) +
                                                                         theme(panel.border = element_rect(colour = "black")) +
                                                                         theme(strip.background = element_rect(colour=NA, fill=NA)) +
                                                                         theme(panel.spacing = unit(0, "lines")) +
                                                                         ggtitle(my_i)
                    
                    
                                                                    pp <- plotly_build(ggplotly(p, dynamicTicks = TRUE))

                                                                    plotmargin_fix(pp) %>% print
                    
                        
                                                                   })
                         })
                        }

  })
  
  
