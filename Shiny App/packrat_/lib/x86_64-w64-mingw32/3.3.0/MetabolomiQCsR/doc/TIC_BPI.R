## ----setup, include=FALSE------------------------------------------------
library(svglite)
knitr::opts_chunk$set(echo = TRUE, fig.align = "center", dev='svglite')

## ----libraries, message=FALSE, warning = FALSE---------------------------
library(MetabolomiQCsR)
library(purrr)
library(tidyr)
library(dplyr)
library(faahKO)
library(magrittr)
library(ggplot2)
library(plotly)
library(knitr)

## ----xcmsRaw_to_tbl1-----------------------------------------------------
files <- file.path(find.package("faahKO"), "cdf/KO") %>% 
         list.files(full.names=TRUE)

files

## ----xcmsRaw_to_tbl2-----------------------------------------------------
raw_tbl <- files %>% xcmsRaw_to_tbl

raw_tbl

## ----xcmsRaw_to_tbl3-----------------------------------------------------
raw_tbl$raw[[1]]

## ----'single TIC'--------------------------------------------------------
TIC_tbl <- raw_tbl$raw[[1]] %>% 
                                get_EICs(range_tbl = data.frame(mz_lower = -Inf,mz_upper = Inf)) %>% 
                                extract2(1) # since the function can work on multiple ranges we get a list. 
                                            # So we take first element.

plot_chrom(TIC_tbl, RT_col = "scan_rt", Intensity_col = "intensity")

## ----'single BPI'--------------------------------------------------------
BPI_tbl <- raw_tbl$raw[[1]] %>% 
                                get_EICs(range_tbl = data.frame(mz_lower = -Inf,mz_upper = Inf), BPI = TRUE) %>% 
                                extract2(1)

plot_chrom(BPI_tbl, RT_col = "scan_rt", Intensity_col = "intensity")

## ----'single TIC with exclusion range'-----------------------------------
TIC_tbl <- raw_tbl$raw[[1]] %>% 
                            get_EICs(range_tbl = data.frame(mz_lower = -Inf, mz_upper = Inf), 
                                     exclude_mz = 279.000, 
                                     exclude_ppm = 1000
                                    ) %>% 
                            extract2(1)

plot_chrom(TIC_tbl, RT_col = "scan_rt", Intensity_col = "intensity")

## ----'single EIC 1'------------------------------------------------------
ppm <- 1000 # this is not accurate mass data

EIC_intervals <- data_frame(mz=279.000, 
                            mz_lower = mz-(ppm/1E6)*mz, 
                            mz_upper = mz+(ppm/1E6)*mz
                           ) 

EIC_intervals

## ----'single EIC 2'------------------------------------------------------
EIC_data <- get_EICs(raw_tbl$raw[[1]], EIC_intervals) %>% extract2(1)
    
EIC_data

p <- plot_chrom(EIC_data, RT_col = "scan_rt", Intensity_col = "intensity")

p

## ----'single EIC 3'------------------------------------------------------

p  %>% ggplotly %>% layout(margin = list(l = 80, b = 60))

## ----'multiple  EIC 1'---------------------------------------------------
ppm <- 1000 # this is not accurate mass data. Used to create intervals below.

range_tbls <-   data_frame(mz = c(508.1, 279.0, 577.3)) %>% 
                mutate(mz_lower = mz-((ppm)/1E6)*mz, 
                       mz_upper = mz+((ppm)/1E6)*mz
                       )

range_tbls

## ----'multiple  EIC 2'---------------------------------------------------
range_tbls %<>% list %>% 
                rep(nrow(raw_tbl)) %>% 
                data_frame(ranges = .)

range_tbls

## ----'multiple  EIC 3'---------------------------------------------------
range_tbls_and_files <- bind_cols(raw_tbl, range_tbls)

range_tbls_and_files %>% select(-path) # In this display we remove the path column just to better show the relevant data.

## ----'multiple  EIC 4'---------------------------------------------------
range_tbls_and_files %<>% mutate(EIC = map2(raw,ranges, get_EICs  ))

range_tbls_and_files  %>% select(-path)

# Inside each of the EIC lists we have a table for each EIC slice:
range_tbls_and_files$EIC[[1]]

## ----'multiple  EIC 5'---------------------------------------------------
range_tbls_and_files %<>% mutate(EIC = map2(EIC,ranges, ~ bind_rows(.x %>% setNames(.y$mz), .id = "mz") %>% 
                                                          mutate(mz = mz %>% as.numeric %>% as.factor) 
                                            )
                                 )

range_tbls_and_files$EIC[[1]]

## ----'multiple  EIC 6'---------------------------------------------------
range_tbls_and_files %<>% select(-ranges, -raw) %>% unnest

## ----'multiple  EIC plots', fig.height = 8, fig.width = 8----------------

p <- range_tbls_and_files %>% 
                                plot_chrom(RT_col = "scan_rt", Intensity_col = "intensity") +
                                facet_grid(file ~ mz) # since plot_chrom gives a ggplot2 object 
                                                      # we can continue manipulating it.

p

## ----'multiple  EIC plots 2'---------------------------------------------

# Nest the table again by file/mz
range_tbls_and_files %<>% group_by(file, mz, path) %>% nest(.key = "EIC")

range_tbls_and_files

# now make the plots
range_tbls_and_files %<>%   mutate(plot = map(EIC, ~ plot_chrom(.x, RT_col = "scan_rt", Intensity_col = "intensity")))
                                
range_tbls_and_files

range_tbls_and_files$plot[[1]]

## ----'multiple  EIC summary'---------------------------------------------
EIC_summary <-  range_tbls_and_files %>% 
                select(-plot) %>% # can't unnest the plot and EIC at the same time 
                unnest %>% 
                group_by(file, mz, path) %>% 
                summarise(EIC_median = median(intensity), 
                          EIC_mean   = mean(intensity), 
                          EIC_sd     = sd(intensity), 
                          EIC_max    = max(intensity)
                          )

EIC_summary %>% select(-path) %>% kable # kable is just to show a nice table below instead of the print display

