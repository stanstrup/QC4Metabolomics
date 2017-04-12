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
require(stringr)


# functions ---------------------------------------------------------------
plotmargin_fix <- function(p){
                                            p$x$layout$margin$l <- p$x$layout$margin$l + 30 # avoid cut axis titles
                                            p$x$layout$margin$b <- p$x$layout$margin$b + 10
                                            p$x$layout$legend$y <- 0.9 # legend at the top
                                            
                                            return(p)
                                        }

distfun  <-     function(x) as.dist(1-cor(t(x)))
hclustfun <-    function(x) hclust(x, method="ward.D2")
    


# Statics -----------------------------------------------------------------
int_range <- "SELECT MAX(cont_data.value) AS max,  MIN(cont_data.value) AS min
              FROM cont_data
              WHERE cont_data.stat IN ('EIC_median', 'EIC_max', 'EIC_mean')
             " %>% 
             dbGetQuery(pool,.) 




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




# Build UI for intensity selection ----------------------------------------
output$int_cutoff_ui <- renderUI({
        ns <- session$ns
                     
        out <- sliderInput(ns("int_cutoff"), 
                    "Minimum intensity in any sample", 
                    min = max(1,ceiling(log10(int_range[1,"min"]))), 
                    max = max(3,floor(log10(int_range[1,"max"]))), 
                    value = 6, 
                    step = 1)
        
        
        # Tell it to update to scientific notation right after the object is made
        value <- paste0("
                         // execute upon document loading
                         $(document).ready(function() {
                                                        // wait a few ms to allow other scripts to execute
                                                        setTimeout(function() {
                                                                                    // include call for each slider
                                                                                    logifySlider('",ns("int_cutoff"),"', sci = true)
                                                                              }, 
                                                                                5
                                                                  )
                                                      }
                                           )
        ")
        
        
        session$sendCustomMessage(type='jsCode', list(value = value))
        
        out

})




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
                                    "SELECT file_info.file_md5 FROM file_info ",
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
    

    
                                metric <- input$int_type %>% as.character
                                cut_off <- 10^(input$int_cutoff) %>% as.character
                                
                                md5_str <- files_tbl_selected() %>% extract2("file_md5") %>% paste(collapse="','") %>% paste0("('",.,"')")
                                
                                ion_id_str <-   paste0("
                                                        SELECT DISTINCT(ion_id)
                                                        FROM cont_data
                                                        WHERE (cont_data.stat = '",metric,"') AND (value > ",cut_off,")
                                                       ") %>% 
                                                dbGetQuery(pool,.) %>% 
                                                extract2("ion_id") %>% 
                                                paste(collapse="','") %>% paste0("('",.,"')")

                                out <- paste0("
                                             SELECT cont_data.*, cont_cmp.name, cont_cmp.mode, cont_cmp.anno, cont_cmp.notes, file_info.sample_id, file_info.time_run, files.path
                                             FROM cont_data
                                             LEFT JOIN cont_cmp USING(ion_id)
                                             LEFT JOIN file_info USING(file_md5)
                                             LEFT JOIN files USING(file_md5)
                                             WHERE (cont_data.stat = '",metric,"') AND (
                                             ion_id IN ", ion_id_str,") AND (
                                             file_md5 IN ",md5_str,")"
                                            ) %>% 
                                    dbGetQuery(pool,.) %>% 
                                    as.tbl %>% 
                                    mutate_each(funs(as.POSIXct(., tz="UTC")), time_run)
                                
                                out
                                })



# PLOT: All heatmaps ------------------------------------------------------
  output$heatmap <- renderPlot({

     data <- std_data_selected()
      
     validate(
              need(length(unique(data$ion_id))>1, "Less than two ions fit the criteria. Not showing anything since clustering would fail.")
             )
      
    
          
          
    # Matrix shapes etc
    data_wide <- data %>% 
                    select(file_md5, value, ion_id) %>% 
                    spread(file_md5, value)
    
    data_wide_mat <- data_wide %>% select(-ion_id) %>% as.matrix %>% unname(force=TRUE)
    data_wide_mat_NA <- data_wide_mat
    data_wide_mat[is.na(data_wide_mat)] <- 0
    
 
    # get cluster order
    pos_idx <- which(data_wide$ion_id>0)
    neg_idx <- which(data_wide$ion_id<0)
    
    c_ord <- data_wide %>% select(ion_id) %>% mutate(c_ord = NA)
    
    if(length(pos_idx)>0){ 
    c_ord_pos <- hclustfun(distfun(data_wide_mat[pos_idx,])) %>% extract2("order") %>% order
        c_ord$c_ord[pos_idx] <- c_ord_pos
    }
    
    if(length(neg_idx)>0){
    c_ord_neg <- hclustfun(distfun(data_wide_mat[neg_idx,])) %>% extract2("order") %>% order
        c_ord$c_ord[neg_idx] <- c_ord_neg
    }
    
    
    data %<>% left_join(c_ord, by="ion_id")
    
    
    
    # Draw heatmaps
    color_scale <- viridis(256, option = "plasma")
    colfunc <- colorRampPalette(c(last(color_scale), "white"))
    color_scale <- rev(c(color_scale,colfunc(20)))
    
   
    
    
    fill_data_pos <- data %>%     
                     filter(mode=="pos") %>% 
                     with( expand.grid(file_md5 = unique(file_md5), ion_id = unique(ion_id), stringsAsFactors = FALSE)) %>% 
                     as.tbl
    
    fill_data_neg <- data %>%     
                     filter(mode=="neg") %>% 
                     with( expand.grid(file_md5 = unique(file_md5), ion_id = unique(ion_id), stringsAsFactors = FALSE)) %>% 
                     as.tbl
    
    
    fill_data <- bind_rows(fill_data_pos, fill_data_neg) %>% 
                 left_join(., data %>% distinct(ion_id, mode, c_ord, name), by="ion_id") %>% 
                 left_join(., data %>% distinct(file_md5, time_run), by="file_md5") %>% 
                 left_join(., data, by=c("file_md5", "ion_id", "mode", "c_ord", "time_run", "name")) %>% 
                 mutate(x_text = paste0(name, " (",ion_id,")"))
                 
    
    metric_name <- input$int_type %>% as.character %>% switch(EIC_max = "max", EIC_median = "median", EIC_mean = "mean")
    
    p <- ggplot(data=fill_data, aes(x=time_run, y = reorder(x_text, c_ord), fill=log10(value))) + 
         geom_tile() +
         scale_fill_gradientn(colours = color_scale, na.value = "white") +
         scale_x_datetime(labels = date_format("%Y-%m"), breaks=date_breaks("1 month")) +
         theme_classic() +
         theme(axis.text.x = element_text(angle=30, hjust = 1)) +
         facet_grid(mode ~ ., scales="free", space="free", labeller = labeller(mode=setNames(paste0("\n", str_to_title(unique(fill_data$mode)), "\n"), unique(fill_data$mode)))) +
         theme(panel.background=element_rect(fill="lightgrey", colour="lightgrey")) +
         labs(x = "Run time", y = "Contaminant") +
         ggtitle("Level of known contaminants over time") +
         guides(fill=guide_legend(title=paste0("Log10 of ",metric_name," intensity\nin chromatogram"), keywidth = 1.5, keyheight = 1.5, title.theme = element_text(size = 12,face = "bold", angle=0 ))) +
         theme(plot.title = element_text(hjust = 0.5, size=22, face="bold")) +
         theme(axis.text = element_text(size=12)) +
         theme(axis.title = element_text(size=16, face="bold")) +
         theme(legend.text = element_text(size=12)) +
         theme(strip.text = element_text(size=12, lineheight=0.5, face="bold"))

    
      p
  })

