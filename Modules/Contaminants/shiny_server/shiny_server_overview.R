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
                                                                                500
                                                                  )
                                                      }
                                           )
        ")
        
        
        session$sendCustomMessage(type='jsCode', list(value = value))
        
        out

})





# Get all data in selected range ------------------------------------------

# Get ALL the data available for the selected files
heatmap_data_selected <-  reactive({

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
                                    mutate_each(~as.POSIXct(., tz="UTC"), time_run) %>% 
                                    mutate(time_run = with_tz(time_run, Sys.timezone(location = TRUE))) # time zone fix
                                
                                out
                                })




# PLOT: heatmap ------------------------------------------------------
  output$heatmap <- renderPlot({

     data <- heatmap_data_selected()
     data <- data %>% mutate(ion_id = if_else(mode == "neg",-ion_id,ion_id)) #this seem to have been expected before
     
      
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
    
    
    
    range_weeks <- difftime(max(fill_data$time_run),min(fill_data$time_run), units = "weeks") %>% as.numeric
    
    if(range_weeks>=20) date_breaks <- "1 month"
    if(range_weeks<20) date_breaks <- "1 week"
    if(range_weeks<2) date_breaks <- "1 day"
    
    
    p <- ggplot(data=fill_data, aes(x=time_run, y = reorder(x_text, c_ord), fill=log10(value))) + 
         geom_tile() +
         scale_fill_gradientn(colours = color_scale, na.value = "white") +
         scale_x_datetime(labels = date_format("%Y-%m-%d", tz = tz(fill_data$time_run)), date_breaks=date_breaks) +
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


