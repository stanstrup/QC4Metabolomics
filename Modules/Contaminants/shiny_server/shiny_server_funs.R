# Functions ---------------------------------------------------------------

plotmargin_fix <- function(p){
                                            p$x$layout$margin$l <- p$x$layout$margin$l + 30 # avoid cut axis titles
                                            p$x$layout$margin$b <- p$x$layout$margin$b + 10
                                            p$x$layout$legend$y <- 0.9 # legend at the top
                                            
                                            return(p)
                                        }


distfun  <-     function(x) dist(x, method="euclidean")
hclustfun <-    function(x) hclust(x, method="ward.D2")
    


timeplot <- function(x,y){ ggplot(data = x, aes(x = time_run, y  = (value))) +
                         geom_point(size=1) +
                         scale_x_datetime(labels = date_format("%Y-%m"), breaks=date_breaks("1 month")) +
                         theme_classic() +
                         theme(axis.text.x = element_text(angle=30, hjust = 1)) +
                         labs(x = "Run time", y = "Intensity") +
                         ggtitle(paste0(sort(x$name)[1]," (",y,")\n",sort(x$anno)[1],"\n", sort(x$notes)[1])) +
                         theme(plot.title = element_text(hjust = 0.5))  +
                         theme(axis.title = element_text(size=16, face="bold"))
                        }


timeplot_plotly <- function(x, y) {
                                    pp <-  ggplotly(y, dynamicTicks = TRUE) %>% 
                                           layout(margin = list(l = 75, b = 75, t = 100)) # fix cut of labels
                                    
                                    
                                    pp$x$data[[1]]$text <- x %>% mutate(filename = sub('\\..*$', '', basename(path))) %>% 
                                                           mutate(text = paste0("Time: ", time_run,"<br>Intensity: ", round(value,0),"<br>Filename:", filename)) %>% 
                                                           extract2("text")
                                    
                                    return(pp)
}


# Constants -----------------------------------------------------------------
int_range <- "
				SELECT MAX(MAX) AS max, MIN(min) AS min FROM (
				SELECT stat, MAX(value) AS max, MIN(value) AS min
				FROM cont_data
				WHERE cont_data.stat IN ('EIC_median', 'EIC_max', 'EIC_mean')
				GROUP BY stat
				) s;
             " %>% 
             dbGetQuery(pool,.) 

if(any(is.na(int_range))){
 int_range[is.na(int_range)] <- 0
}


