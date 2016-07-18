# libraries ---------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(plotly)
library(scales)



# Some test data ----------------------------------------------------------
data %>% select(-raw) %>%  # we remove raw so it is like we just pulled the path from a db
         mutate(raw   = map(.$path %>% as.character, xcmsRaw)  ) -> # get raw data
    test
    


# Plot normal TIC ---------------------------------------------------------
test %>%    mutate(TIC = map(raw, get_TIC )) %>% 
            mutate(TIC_plot = map(TIC,plot_TIC)) %>% 
            mutate(TIC_plotly = map(TIC_plot, ggplotly)) ->
p


# Plot tic with excluded masses -------------------------------------------
test %>%    mutate(TIC = map(raw, ~ get_TIC(., TIC_exclude_mz = QC4Metabolomics.env$TIC$TIC_exclude ) )) %>% 
            mutate(TIC_plot = map(TIC,plot_TIC)) %>% 
            mutate(TIC_plotly = map(TIC_plot, ggplotly)) ->
p

