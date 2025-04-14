library(MetabolomiQCsR)
library(dplyr)
library(ggplot2)
library(plotly)
library(RColorBrewer)
library(ggbreak)
library(tidyr)
library(ggpmisc)
library(ggh4x)
library(DBI)
set_QC4Metabolomics_settings_from_file("settings_remote.env")
pool <- dbPool_MetabolomiQCs(30)


# get data ---------------------------------------------
std_stat_data <-  paste0("
                    SELECT * FROM std_stat_data
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


std_compounds <-  paste0("
                    SELECT * FROM std_compounds
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


std_stat_types <-  paste0("
                    SELECT * FROM std_stat_types
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


file_info <-  paste0("
                    SELECT * FROM file_info
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


files <-  paste0("
                    SELECT * FROM files
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble


data <- std_stat_data %>% 
          left_join(std_compounds, by = c("cmp_id") ) %>%
          left_join(std_stat_types, by = "stat_id" ) %>%
          left_join(file_info, by = c("file_md5", "instrument", "mode") ) %>% 
          left_join(files, by = c("file_md5") )



data_select <- data %>% 
  filter(grepl("Tryptophan", cmp_name)) %>%
  filter( stat_name %in% c("mz", "rt", "into", "mz_dev_ppm", "rt_dev")) %>% 
  mutate(time_run = as.POSIXct(time_run)) %>% 
  pivot_wider(id_cols = c(file_md5, path, sample_id, instrument, project, time_run, mode, cmp_name, cmp_mz, cmp_rt1, found), names_from = stat_name , values_from = value) %>% 
  filter(
         instrument %in% c("Snew", "Qnew"), 
         (!(instrument == "Qnew" & time_run>"2016-01-01"))
         )
  


## all data
p <- ggplot(data_select, aes(time_run, mz_dev_ppm, color = project, label = path)) +
  geom_point() +
  facet_grid(mode~instrument, scales = "free_x")+
  geom_hline(yintercept = 0) +
  ylab("m/z deviation (ppm)") +
  scale_y_continuous(breaks = seq(-100, 100, by = 10))+
  guides(color=guide_legend(ncol=2,byrow=TRUE)) +
  ggtitle("Tryptophan m/z deviation over time\non Premier Qtof and Synapt")+
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))+
  theme(legend.position="bottom")

p

ggsave(plot = p, "plot_mz_all.png", dpi = 300, height = 20, width = 12)



