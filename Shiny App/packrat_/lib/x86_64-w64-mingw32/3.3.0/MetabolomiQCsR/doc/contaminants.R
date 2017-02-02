## ----setup, include=FALSE------------------------------------------------
library(svglite)
knitr::opts_chunk$set(echo = TRUE, fig.align = "center", dev='svglite')

## ----libraries, message=FALSE, warning = FALSE---------------------------
library(MetabolomiQCsR)
library(purrr)
library(tidyr)
library(tibble)
library(dplyr)
library(magrittr)
library(knitr)
library(ggplot2)
library(plotly)
library(scales)

## ----contaminant list----------------------------------------------------
contaminant_list <- get_cont_list(polarity = c("positive", "negative", "unknown"))
contaminant_list %>% str

## ----contaminant list table----------------------------------------------
contaminant_list[[1]] %>% 
                            slice(1:20) %>% 
                            select(-ESI, -MALDI, -References) %>% 
                            kable

## ----input files---------------------------------------------------------
files <- c("Z:/_Data/LIP1/0000_Test/2016-06-24 - Contamination hunt - part I/Infusion tests/mzML_centroided/IPA_VWR_Boiled.mzML",
           "Z:/_Data/LIP1/0000_Test/2016-06-24 - Contamination hunt - part I/Infusion tests/mzML_centroided/EluentB_IPA1_Boiled.mzML",
           "Z:/_Data/LIP1/0036_SevaMeal/mzML/0036_LIP1p_20160201_034_2_1_1.mzML",
           "Z:/_Data/LIP1/0036_SevaMeal/mzML/0036_LIP1p_20160201_057_36_1_1.mzML"
)

## ----read raw files------------------------------------------------------
data_raw <- xcmsRaw_to_tbl(files)

## ----list of contaminants------------------------------------------------
data_cont <-    data_raw %>% 
                distinct(polarity) %>% 
                mutate(cont_list = get_cont_list(polarity))

## ----clean contaminant list----------------------------------------------
EIC_ppm <- MetabolomiQCsR.env$target_cont$EIC_ppm # 30

data_cont %<>%  unnest(cont_list, .drop = FALSE) %>%  # one line per contaminant
                setNames(make.names(names(.))) %>% 
                mutate(comp_name = paste0(Compound.ID.or.species," (",Ion.type,", ", round(Monoisotopic.ion.mass..singly.charged.,4),")"), comp_mz = Monoisotopic.ion.mass..singly.charged. ) %>% 
                mutate(mz_lower = comp_mz-((EIC_ppm)/1E6)*comp_mz, mz_upper = comp_mz+((EIC_ppm)/1E6)*comp_mz) %>% 
                nest(-polarity, .key = contaminants)

## ----merge tables--------------------------------------------------------
data <- left_join(data_raw,data_cont, by = "polarity")

rm(data_cont,data_raw)

## ----EIC for each contaminant--------------------------------------------
data %<>%    mutate(   EIC = map2( raw, contaminants, get_EICs )   )

## ----EIC unnest contaminants and EIC-------------------------------------
data %<>%   mutate(EIC = map2(EIC,contaminants, ~ bind_cols(.y, data_frame(EIC = .x) ))) %>% 
            select(-raw,-contaminants) %>% 
            unnest

data %>% select(file, polarity, comp_name, comp_mz, mz_lower, mz_upper, EIC)  %>% print(width=Inf)

## ----'multiple  EIC summary'---------------------------------------------
EIC_summary <-  data %>% 
                unnest %>% 
                group_by(file, comp_name, comp_mz, path) %>% 
                summarise(EIC_median = median(intensity), 
                          EIC_mean   = mean(intensity), 
                          EIC_sd     = sd(intensity), 
                          EIC_max    = max(intensity)
                          ) %>% 
                ungroup %>% 
                filter(EIC_median > 0)

EIC_summary %>% select(-path) %>% slice(1:10) %>% kable # kable is just to show a nice table below instead of the print display

## ----EIC plotting contamination profile, fig.height = 8, fig.width = 9----
EIC_summary %>% 
                mutate(sample = gsub(".mzML","",file)) %>% 
                mutate(sample = factor(sample,levels=unique(sample))) %>%
                select(sample,comp_name,EIC_median) %>%
                mutate(comp_name = factor(comp_name,levels=unique(comp_name)) ) %>%
                nest(-sample) %>% 
                mutate(gg = map2(data, sample, plot_contaminants))     ->
EIC_plots


EIC_plots %<>% mutate(  ggp = map(gg, plotly_build)  ) %>%
               mutate(  ggp = map(ggp, ~ plotly_clean_tt(.x, rep=c(`comp_name:` = "<b>Compound:</b>", `EIC_median:` = "<b>EIC Median:</b>"))    )  )

EIC_plots$ggp[[1]] 

