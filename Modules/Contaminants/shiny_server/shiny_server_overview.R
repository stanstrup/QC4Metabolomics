dbGetQuery_sel_no_warn <- MetabolomiQCsR:::selectively_suppress_warnings(dbGetQuery, pattern = "unrecognized MySQL field type 7 in column 12 imported as character")


# Build UI for intensity selection ----------------------------------------
output$int_cutoff_ui <- renderUI({
        ns <- session$ns
                     
        out <- sliderInput(ns("int_cutoff"), 
                    "Minimum intensity in any sample", 
                    min   = max(1,ceiling(log10(int_range[1,"min"]))), 
                    max   = max(3,floor(log10(int_range[1,"max"]))), 
                    value = max(3,floor(log10(int_range[1,"max"]))), 
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


                                query <- paste0("
                                                  WITH filtered_cont_data AS (
                                                      SELECT *
                                                      FROM cont_data
                                                      WHERE stat = '", metric, "' AND file_md5 IN ", md5_str, "
                                                  ),
                                                  filtered_ions AS (
                                                      SELECT DISTINCT ion_id, mode
                                                      FROM cont_data
                                                      WHERE stat = '", metric, "' AND value > ", cut_off, " AND file_md5 IN ", md5_str, "
                                                  )
                                                  SELECT f.*, cmp.name, cmp.anno, cmp.notes, fi.sample_id, fi.time_run, files.path
                                                  FROM filtered_cont_data f
                                                  INNER JOIN filtered_ions i
                                                      ON f.ion_id = i.ion_id AND f.mode = i.mode
                                                  LEFT JOIN cont_cmp cmp
                                                      ON f.ion_id = cmp.ion_id AND f.mode = cmp.mode
                                                  LEFT JOIN file_info fi
                                                      ON f.file_md5 = fi.file_md5
                                                  LEFT JOIN files
                                                      ON f.file_md5 = files.file_md5
                                                  ")
                                
                                out <- dbGetQuery_sel_no_warn(pool, query) %>%
                                  as_tibble() %>%
                                  mutate(across(time_run, ~as.POSIXct(., tz = "UTC"))) %>%
                                  mutate(time_run = with_tz(time_run, Sys.timezone(location = TRUE)))

                                
                                })






# PLOT: heatmap ------------------------------------------------------
  output$heatmap <- renderPlot({

     data <- heatmap_data_selected()
     
     validate(
              need(length(unique(data$ion_id))>1, "Less than two ions fit the criteria. Not showing anything since clustering would fail.")
             )
      
    
          
          
    # Matrix shapes etc
    data_wide <- data %>% 
                    select(file_md5, value, ion_id, mode) %>% 
                    spread(file_md5, value)
    
    data_wide_mat <- data_wide %>% select(-ion_id, -mode) %>% as.matrix %>% unname(force=TRUE)
    data_wide_mat_NA <- data_wide_mat
    data_wide_mat[is.na(data_wide_mat)] <- 0
    
 
    # get cluster order
    pos_idx <- which(data_wide$mode == "pos")
    neg_idx <- which(data_wide$mode == "neg")
    
    c_ord <- data_wide %>% select(ion_id, mode) %>% mutate(c_ord = NA)
    
    if(length(pos_idx)>1){ 
    c_ord_pos <- hclustfun(distfun(t(scale(t(data_wide_mat[pos_idx,]))))) %>% extract2("order") %>% order
        c_ord$c_ord[pos_idx] <- c_ord_pos
    }else{
       c_ord$c_ord[pos_idx] <- 1
    }
    
    
    if(length(neg_idx)>1){
    c_ord_neg <- hclustfun(distfun(data_wide_mat[neg_idx,])) %>% extract2("order") %>% order
        c_ord$c_ord[neg_idx] <- c_ord_neg
    }else{
       c_ord$c_ord[neg_idx] <- 1
    }
    
    
    data %<>% left_join(c_ord, by=c("ion_id", "mode"))
    
    
    
    # Draw heatmaps
    color_scale <- viridis(256, option = "plasma")
    colfunc <- colorRampPalette(c(last(color_scale), "white"))
    color_scale <- rev(c(color_scale,colfunc(20)))
    
   
    
    
    fill_data_pos <- data %>%     
                     filter(mode=="pos") %>% 
                     with( expand.grid(file_md5 = unique(file_md5), ion_id = unique(ion_id), stringsAsFactors = FALSE)) %>% 
                     as_tibble %>% 
                     mutate(mode = "pos")
    
    fill_data_neg <- data %>%     
                     filter(mode=="neg") %>% 
                     with( expand.grid(file_md5 = unique(file_md5), ion_id = unique(ion_id), stringsAsFactors = FALSE)) %>% 
                     as_tibble %>% 
                     mutate(mode = "neg")
    
    
    fill_data <- bind_rows(fill_data_pos, fill_data_neg) %>% 
                 left_join(., data %>% distinct(ion_id, mode, c_ord, name), by=c("ion_id", "mode")) %>% 
                 left_join(., data %>% distinct(file_md5, time_run), by="file_md5") %>% 
                 left_join(., data, by=c("file_md5", "ion_id", "mode", "c_ord", "time_run", "name")) %>% 
                 mutate(x_text = paste0(name, " (",ion_id,")"))
                 
    
    metric_name <- input$int_type %>% as.character %>% switch(EIC_max = "max", EIC_median = "median", EIC_mean = "mean")
    

    # create rank (order of files) and "fill" until next file in same mode
    fill_data <- fill_data %>% 
                    filter(!is.na(stat)) %>% # nothing found
                    distinct(ion_id, mode, c_ord, name, time_run, stat, value, anno, notes, x_text) %>% # some files are there twice with different md5
                    
                    dplyr::mutate(rank = dense_rank(time_run)) %>% 
                    
                    group_by(mode, ion_id, stat) %>% 
                    dplyr::arrange(mode, ion_id, stat, time_run) %>% 
                    
                    dplyr::mutate(x_end = lead(rank, 1)) %>% 
                    ungroup %>% 
                    dplyr::mutate(x_end = if_else(is.na(x_end),max(rank),x_end) )
    
    
    # use negative numbers for negative mode so we can assign labels differently for pos and neg
    fill_data <- fill_data %>% mutate(c_ord = if_else(mode == "neg", -c_ord, c_ord))
    
    y_labels <- fill_data %>% distinct(c_ord, x_text)
    
    
    # get data breaks
    x_breaks <- fill_data %>% 
                    distinct(rank, time_run) %>% 
                    arrange(rank) %>% 
                    slice(round(seq.int(min(rank), max(rank), length.out = 10), 0)) %>% 
                    mutate(time_run = format(time_run, format='%Y-%m-%d %H:%M'))
    
    
    
    
    p <- ggplot(data=fill_data, aes(xmin = rank, 
                                    xmax = x_end, 
                                    ymin = c_ord-0.5, 
                                    ymax = c_ord+0.5, 
                                    fill=log10(value)
                                    )
                ) + 
         geom_rect() +
         scale_fill_gradientn(colours = color_scale, na.value = "white") +
         scale_y_continuous(breaks = y_labels$c_ord, labels = y_labels$x_text, expand = c(0,0)) +
         scale_x_continuous(breaks = x_breaks$rank, labels = x_breaks$time_run) +
         theme_classic() +
         theme(axis.text.x = element_text(angle=30, hjust = 1)) +
         facet_grid(mode~. , scales="free_y", space="free", labeller = labeller(mode=setNames(paste0("\n", str_to_title(unique(fill_data$mode)), "\n"), unique(fill_data$mode)))) +
        
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
  },height = exprToFunction(17*nrow(distinct(heatmap_data_selected(), ion_id, stat))+300), res = 100
  )

# ggsave(plot = p, file="manual_contaminants_poster.pdf", height = 7, width = 10)

  