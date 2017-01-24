# functions ---------------------------------------------------------------
stat_name2id <- . %>% paste0("SELECT * FROM std_stat_types WHERE stat_name = '",.,"'") %>% dbGetQuery(pool,.) %>% extract2("stat_id")

std_stats_plot_common <- function(p){ p+
                                      geom_line() +
                                      geom_point(aes(text = paste("Filename:", filename))) +
                                      theme_gdocs() +
                                      theme(axis.title=element_text(face="bold", size = 16), title=element_text(face="bold", size = 18)) +
                                      labs(group="", color="")
                                    }

# Get all data in selected range ------------------------------------------

# Need time, project and mode limit selection
# Filter by type: blank, std etc?

files_tbl_selected <- "SELECT * FROM files" %>% dbGetQuery(pool,.) %>% as.tbl



std_data_selected <- files_tbl_selected %>% 
                     extract2("file_md5") %>% 
                     paste(collapse="','") %>% 
                     paste0("'",.,"'") %>% 
                     paste0("
                             SELECT std_stat_data.*, std_compounds.cmp_name, std_compounds.cmp_rt1, std_compounds.updated_at, files.time_run, files.path
                             FROM std_stat_data
                             LEFT JOIN std_compounds USING(cmp_id)
                             LEFT JOIN files USING(file_md5)
                             WHERE std_stat_data.file_md5 in (",.,")
                            ") %>% 
                     dbGetQuery(pool,.) %>% 
                     as.tbl %>% 
                    mutate_each(funs(as.POSIXct(., tz="UTC", format="%Y-%m-%d %H:%M:%S")), updated_at, time_run) %>% 
                    mutate(filename = sub('\\..*$', '', basename(path)))





# Retention time deviation ------------------------------------------------
output$std_stats_rtplot <- renderPlotly({
     
    p <- std_data_selected %>% 
                                filter(stat_id == stat_name2id("rt")) %>% 
                                mutate(rt_dev = value-cmp_rt1) %>% 
            
                                ggplot(aes(x=time_run, y=rt_dev, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "Retention time deviation (min)", x = "Run time") +
                                ggtitle("Retention time deviation")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    
    p$x$layout$margin$l <- p$x$layout$margin$l + 30 # avoid cut axis titles
    p$x$layout$margin$b <- p$x$layout$margin$b + 10
    p$x$layout$legend$y <- 0.9 # legend at the top
    
    print(p)
    
})


# mz deviation ------------------------------------------------
output$std_stats_mzplot <- renderPlotly({
     
    p <- std_data_selected %>% 
                                filter(stat_id == stat_name2id("mz_dev_ppm")) %>% 
            
                                ggplot(aes(x=time_run, y=value, group=cmp_name, color=cmp_name)) %>% 
                                {std_stats_plot_common(.) + 
                                labs(y = "<i>m/z</i> deviation (ppm)", x = "Run time") +
                                ggtitle("<i>m/z</i> deviation")} %>% 
            
                                ggplotly(dynamicTicks = TRUE, tooltip = c("group", "text", "x", "y")) %>% 
                                plotly_build
    
    
    
    p$x$layout$margin$l <- p$x$layout$margin$l + 30 # avoid cut axis titles
    p$x$layout$margin$b <- p$x$layout$margin$b + 10
    p$x$layout$legend$y <- 0.9 # legend at the top
    
    print(p)
    
})
