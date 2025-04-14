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
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

p


ggplotly(p)


  
  
  
  
  
  

## selected example

my_palette <- brewer.pal(name="Set1",n=9)[-6]
my_palette <- rep(my_palette, 10)

p <- data_select %>% 
    filter(time_run>"2022-05-29", time_run<"2022-10-01", mode == "neg", found == 1) %>% 
    filter(!(project %in% c("STD", "Tryptophan metabolites", "DIMEurine", "M185ms2", "METNEXS", "M198"))) %>% # very few samples or outside range
    filter(!grepl("Blank|3x|10x",sample_id , ignore.case = TRUE)) %>% 
    arrange(time_run) %>% 
    mutate(project = factor(project, unique(project))) %>% 
    # mutate(project = factor(project, labels = paste0("Project ", 1:length(unique(project))))) %>% 
  
      ggplot(aes(time_run, mz_dev_ppm, color = project, label = path)) +
      geom_point() +
      geom_hline(yintercept = 0) +
      ylab("m/z deviation (ppm)") +
      xlab("Analysis date") +
      theme_bw()+
      theme(legend.title=element_blank()) +
      scale_y_continuous(breaks = seq(-100, 100, by = 10))+
      guides(color=guide_legend(nrow=1,byrow=TRUE)) +
      #ggtitle("Tryptophan m/z deviation over time\non Premier Qtof and Synapt")+
      theme(plot.title = element_text(hjust = 0.5, face = "bold")) +
      scale_color_manual(values = my_palette) +
      scale_x_break(as.POSIXct(c("2022-06-02 00:00", "2022-06-17 11:00",      
                                 "2022-06-21 12:00", "2022-09-14 00:00", 
                                 "2022-09-17 00:00", "2022-09-27 00:00"   
      )
      )
      ) +
      # scale_x_datetime(date_breaks = "1 day", limits = as.POSIXct(c("2022-06-01", "2022-10-09"))) +
      scale_x_datetime(date_breaks = "1 day") +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
      theme(axis.text.x.top = element_blank(), # remove additional top scale that scale_x_break creates
            axis.ticks.x.top = element_blank(),
            axis.line.x.top = element_blank()) +
      theme(legend.position="bottom")


p


ggplotly(p)

# find more samples in this time-frame

# raw_files <- readRDS("i:/SCIENCE-NEXS-NyMetabolomics/Projects/raw_files_survey.rds")
# 
# 
# raw_files %>% 
#   mutate(time_run = as.POSIXct(paste(date, time), format="%d-%b-%Y %H:%M:%S")) %>% 
#   filter(time_run>"2022-06-01", time_run<"2022-07-28") 


# hot facets:       I:\SCIENCE-NEXS-NyMetabolomics\Projects\M240 Hotfacets.pro\mzML_all_func
# FecalFamus:       I:\SCIENCE-NEXS-NyMetabolomics\Projects\Famus\Fecal\Data\mzML_all_func
# MarlouDirksRerun: I:\SCIENCE-NEXS-NyMetabolomics\Projects\MarlouDirksRerun\MarlouDirksRerun.pro\mzML_all_func


# for fun
# do intensity correlate with mz_div?
# in a certain intensity range yes!

data_test <- data %>% 
filter(time_run>"2022-05-29", time_run<"2022-10-01", mode == "neg", found == 1) %>% 
    filter(!(project %in% c("STD", "Tryptophan metabolites", "DIMEurine", "M185ms2", "METNEXS", "M198"))) %>% # very few samples or outside range
    filter(!grepl("Blank|3x|10x",sample_id , ignore.case = TRUE)) %>% 
  mutate(time_run = as.POSIXct(time_run)) %>% 
  filter(grepl("Tryptophan", cmp_name), 
         instrument %in% c("Snew", "Qnew"), 
         
         (!(instrument == "Qnew" & time_run>"2016-01-01"))
         )
  

p <- data_test %>% 
  pivot_wider(id_cols = c(file_md5, path, project), names_from = stat_name , values_from = value) %>% 
  # filter(into > 200, into<5000) %>% 
  mutate(project = factor(project, unique(project))) %>% 
ggplot(aes(into, mz_dev_ppm))+
  geom_point() +
  geom_hline(yintercept = 0) +
  stat_poly_line() +
  stat_poly_eq(use_label(c("eq", "adj.R2", "p", "n")))+
  theme_bw()+
  facet_grid(.~project)

p

#ggplotly(p)



# New example where it IS a loss of LeuEnk --------------------------------



my_palette <- brewer.pal(name="Set1",n=9)[-6]
my_palette <- rep(my_palette, 10)

p <- data_select %>% 
    filter(time_run>"2022-09-13", time_run<"2023-04-10", mode == "neg", found == 1) %>% 
    filter(!(project %in% c("STD", "Tryptophan metabolites", "DIMEurine", "M185ms2", "M198"))) %>% # very few samples or outside range
    filter(!grepl("Blank|3x|10x",sample_id , ignore.case = TRUE)) %>% 
    arrange(time_run) %>% 
    mutate(project = factor(project, unique(project))) %>% 
    # mutate(project = factor(project, labels = paste0("Project ", 1:length(unique(project))))) %>% 
  
      ggplot(aes(time_run, mz_dev_ppm, color = project, label = path)) +
      annotate("rect", 
               xmin = as.POSIXct("2022-09-14", format = "%Y-%m-%d"),
               xmax = as.POSIXct("2022-10-08", format = "%Y-%m-%d"),
               ymin = -Inf, 
               ymax = Inf, 
               fill="#ccebc5",  
               alpha = .4) +
      annotate("rect", 
               xmin = as.POSIXct("2022-10-08", format = "%Y-%m-%d"),
               xmax = as.POSIXct("2023-02-01", format = "%Y-%m-%d"),
               ymin = -Inf, 
               ymax = Inf, 
               fill="#ffffcc",  
               alpha = .6) +
      annotate("rect", 
               xmin = as.POSIXct("2023-02-01", format = "%Y-%m-%d"),
               xmax = as.POSIXct("2023-03-15", format = "%Y-%m-%d"),
               ymin = -Inf, 
               ymax = Inf, 
               fill="#fbb4ae",  
               alpha = .4) +
      annotate("rect", 
               xmin = as.POSIXct("2023-03-15", format = "%Y-%m-%d"),
               xmax = as.POSIXct("2023-04-09", format = "%Y-%m-%d"),
               ymin = -Inf, 
               ymax = Inf, 
               fill="#ccebc5",  
               alpha = .4) +

      geom_point() +
      geom_hline(yintercept = 0) +
      ylab("m/z deviation (ppm)") +
      xlab("Analysis date") +
      theme_bw()+
      theme(legend.title=element_blank()) +
      scale_y_continuous(breaks = seq(-100, 100, by = 10), limits = c(-80,80))+
      guides(color=guide_legend(nrow=1,byrow=TRUE)) +
      #ggtitle("Tryptophan m/z deviation over time\non Premier Qtof and Synapt")+
      theme(plot.title = element_text(hjust = 0.5, face = "bold")) +
      scale_color_manual(values = my_palette) +
      scale_x_break(as.POSIXct(c("2022-09-17 00:00", "2022-09-27 00:00",
                                 "2022-09-30 12:00", "2022-10-03 12:00",
                                 "2022-10-06 00:00", "2022-10-27 00:00",
                                 "2022-10-28 12:00", "2023-01-11 12:00",
                                 "2023-01-12 12:00", "2023-01-17 12:00",
                                 "2023-01-18 12:00", "2023-02-16 12:00",
                                 "2023-02-17 12:00", "2023-02-20 12:00",
                                 "2023-02-23 00:00", "2023-03-29 00:00",
                                 "2023-03-31 12:00", "2023-04-04 00:00"
                                 
                                )
                              ),
                    space =0
      ) +
      # scale_x_datetime(date_breaks = "1 day", limits = as.POSIXct(c("2022-06-01", "2022-10-09"))) +
      scale_x_datetime(date_breaks = "1 day" ) +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))+
      theme(axis.text.x.top = element_blank(), # remove additional top scale that scale_x_break creates
            axis.ticks.x.top = element_blank(),
            axis.line.x.top = element_blank()) +
      theme(legend.position="bottom")


p


ggplotly(p)



# stats -------------------------------------------------------------------

data_select %>% 
  group_by(instrument, mode) %>% 
  summarise(n= n(), 
            mz_dev_ppm_abs_median = median(abs(mz_dev_ppm), na.rm = T), 
            mz_dev_ppm_abs_mean = mean(abs(mz_dev_ppm), na.rm = T), 
            mz_dev_ppm_sd = sd(mz_dev_ppm, na.rm = T ),
            
            rt_dev_abs_median = median(abs(rt_dev ), na.rm = T), 
            rt_dev_abs_mean = mean(abs(rt_dev ), na.rm = T), 
            rt_dev_sd = sd(rt_dev , na.rm = T ),
            
            .groups = "drop"
             
            )




# combine both examples ---------------------------------------------------
my_palette <- c(brewer.pal(name="Set1",n=9)[-6], brewer.pal(name="Set2",n=8)[-6])
my_palette <- rep(my_palette, 10)

p_dat <- data_select %>% 
    filter(time_run>"2022-05-29", time_run<"2023-04-10", mode == "neg", found == 1) %>% 
    filter(!(project %in% c("STD", "Tryptophan metabolites", "DIMEurine", "M185ms2", "M198"))) %>% # very few samples or outside range
    filter(!grepl("Blank|3x|10x",sample_id , ignore.case = TRUE)) %>% 
    arrange(time_run) %>% 
    mutate(project = factor(project, unique(project))) %>% 
    pivot_longer(cols = -c(file_md5, path, sample_id, instrument, project, time_run, mode, cmp_name , cmp_mz, cmp_rt1, found) ) %>% 
    filter(name %in% c("into", "mz_dev_ppm")) %>% 
    mutate(project = factor(project, labels = paste0("Project ", 1:length(unique(project))))) %>% 
    mutate(name = case_when( name == "into" ~ "Relative intensity",
                             name == "mz_dev_ppm" ~ "m/z deviation (ppm)",
                             )
           ) %>% 
    mutate(name = factor(name, c("Relative intensity", "m/z deviation (ppm)")))
  

p_anno <- tribble(
   ~time_start, ~time_end, ~fill, ~ alpha,
  "2022-05-30", "2022-06-03", "#ccebc5", .4, 
  "2022-06-17", "2022-06-22", "#fbb4ae", .4,
  "2022-07-08", "2022-10-08", "#ccebc5", .4,
  "2022-10-08", "2023-02-01", "#ffffcc", .6,
  "2023-02-01", "2023-03-15", "#fbb4ae", .4,
  "2023-03-15", "2023-04-09", "#ccebc5", .4
  ) %>% 
  mutate(time_start = as.POSIXct(time_start, format = "%Y-%m-%d"),
         time_end = as.POSIXct(time_end, format = "%Y-%m-%d")) %>% 
  slice(rep(1:n(), 2)) %>% 
  mutate(name = rep(c("Relative intensity", "m/z deviation (ppm)"), each = n()/2)) %>%
  mutate(ymin = rep(c(10^-10, -100), each = n()/2)) %>%
  mutate(ymax = rep(c(10^10, 100), each = n()/2)) %>% 
  mutate(name = factor(name, c("Relative intensity", "m/z deviation (ppm)")))



fill_colors <- pull(p_anno, fill) %>% unique %>% setNames(.,.)
fill_alphas <- pull(p_anno, alpha) %>% unique %>% setNames(.,.)

p <- ggplot(data = p_dat, aes(label = path)) +
      geom_rect(data = p_anno, aes(xmin = time_start, xmax = time_end, fill = fill, alpha = as.factor(alpha), ymin = ymin, ymax = ymax), inherit.aes = FALSE) +
      scale_fill_manual(values = fill_colors) +
      scale_alpha_manual(values = fill_alphas) +
      scale_color_manual(values = my_palette) +
  
      geom_point(data = p_dat, aes(time_run, value, color = project), size = 1) +
      geom_hline(yintercept = 0) +
  
      xlab("Analysis date") +
      facet_grid(name~., scales = "free_y", switch  = "y") +
      facetted_pos_scales(y = list(
                                    name == "Relative intensity" ~        scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x), labels = scales::trans_format("log10", scales::math_format(10^.x)), limits = c(10^1,10^4.5)),
                                    name == "m/z deviation (ppm)" ~ scale_y_continuous(breaks = seq(-100, 100, by = 20), limits = c(-80,80), minor_breaks = NULL)
                                  )
                         ) +
  
      guides(color=guide_legend(nrow=2, 
                                byrow=TRUE, 
                                )
             
            ) +
      guides(fill="none", alpha="none") +
  
      scale_x_datetime(date_breaks = "1 day" ) +
      scale_x_break(as.POSIXct(c("2022-06-02 00:00", "2022-06-17 11:00",
                                 "2022-06-18 18:00", "2022-07-08 00:00",
                                 "2022-07-09 00:00", "2022-06-20 09:00",
                                 "2022-06-21 12:00", "2022-09-14 01:00",
                                 "2022-09-16 18:00", "2022-09-27 00:00",
                                 "2022-09-30 12:00", "2022-10-03 12:00",
                                 "2022-10-06 12:00", "2022-10-27 12:00",
                                 "2022-10-28 12:00", "2023-01-11 12:00",
                                 "2023-01-12 12:00", "2023-01-17 12:00",
                                 "2023-01-18 12:00", "2023-02-16 12:00",
                                 "2023-02-17 12:00", "2023-02-20 12:00",
                                 "2023-02-23 00:00", "2023-03-29 01:00",
                                 "2023-03-31 12:00", "2023-04-04 00:00"
                                 
                                )
                              ),
                    space =0, expand = FALSE
      ) +
      theme_bw() +
      theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
            axis.text.x.top = element_blank(), # remove additional top scale that scale_x_break creates
            axis.ticks.x.top = element_blank(),
            axis.line.x.top = element_blank(),
            axis.title.y=element_blank(),
            legend.position="bottom",
            legend.title=element_blank(),
            legend.margin = margin(0, 0, 0, 0),
            legend.spacing.x = unit(0, "mm"),
            legend.spacing.y = unit(0, "mm")
            )

p

#ggplotly(p)



ggsave(plot = p, filename = "../QC4Metabolomics-paper/figures/combined.pdf", width = 14*0.55, height = 10*0.55)












