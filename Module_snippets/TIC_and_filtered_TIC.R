library(dplyr)
library(ggplot2)
library(plotly)
library(scales)

data %>% select(-raw) %>%  # we remove raw so it is like we just pulled the path from a db
         mutate(raw   = map(.$path %>% as.character, xcmsRaw)  ) -> # get raw data
    test
    


# Plot normal TIC ---------------------------------------------------------

test %>% 
            mutate(TIC = map(raw, get_TIC )) %>% 
            group_by(file) %>% unnest(TIC) %>% 
            do(
                TIC_plot =  ggplot(data=.,aes(x = RT, y = Intensity)) + 
                            geom_line(size=0.2) +
                            theme_bw() +
                            theme(
                                plot.background = element_blank()
                                ,panel.grid.major = element_blank()
                                ,panel.grid.minor = element_blank()
                                ,panel.border = element_blank()
                            ) +
                            #draws x and y axis line
                            theme(axis.line.x = element_line(color="black", size = 0.5),
                                  axis.line.y = element_line(color="black", size = 0.5)) + 
                            labs(x="Retention time (min)", y="Intensity (counts)") +
                            theme(axis.title = element_text(size = 16,face = "bold")) +
                            scale_y_continuous(label=scientific) +
                            expand_limits(x = 0, y = 0) +
                            geom_hline(yintercept=0, size=0.5)
            ) %>% 
            ungroup %>% 
            mutate(TIC_plot = map(TIC_plot, ggplotly)) ->
p


# TIC with masses excluded ------------------------------------------------

