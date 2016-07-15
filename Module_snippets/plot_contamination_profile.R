library(dplyr)
library(ggplot2)
library(plotly)
library(scales)

data_cont %>% 
                mutate(sample = gsub(".mzML","",file)) %>% 
                mutate(sample = factor(sample,levels=unique(sample))) %>%
                select(sample,comp_name,EIC_median) %>%
                mutate(comp_name = factor(comp_name,levels=unique(comp_name)) ) %>% 

                group_by(sample) %>% 
                do(
                    plot =  ggplot(data=.,aes(x = reorder(comp_name, -EIC_median), y = EIC_median)) + 
                        geom_bar(stat = "identity",fill="black") +
                        theme_classic() +
                        theme(axis.text.x = element_text(hjust=1,size = 10, angle = 90, vjust = 0.5)) +
                        theme(axis.title = element_text(size = 16,face = "bold")) +
                        theme(axis.ticks=element_blank()) +
                        ggtitle(.$sample %>% unique %>% as.character) +
                        theme(plot.title = element_text(margin=margin(b = 50),face="bold",size=32)) +
                        labs(x="Contaminants", y="Median EIC") +
                        scale_y_continuous(label=scientific)
                ) ->
p


p %<>% ungroup %>% mutate(  plotly = map(plot, cont_screen_gg2plotly)  )

