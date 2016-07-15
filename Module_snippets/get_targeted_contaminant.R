# Libraries ---------------------------------------------------------------
library(purrr)
library(magrittr)
library(tibble)
library(dplyr)
library(tidyr)



# Read raw data -----------------------------------------------------------
data <- xcmsRaw_to_tbl(files)



# Get contamination lists -------------------------------------------------
data_cont <-    data %>% 
                mutate(cont_list = get_cont_list(polarity,type=QC4Metabolomics.env$target_cont$cont_list$cont_list_type))



# Get EICs of all known contaminants --------------------------------------

data_cont %<>%  unnest(cont_list, .drop = FALSE) %>%  # one line per contaminant
                mutate(comp_name = paste0(`Compound ID or species`," (",`Ion type`,", ",round(`Monoisotopic ion mass (singly charged)`,4),")"), comp_mz = `Monoisotopic ion mass (singly charged)`) %>% 
                mutate(mz_lower = comp_mz-((QC4Metabolomics.env$target_cont$EIC_ppm)/1E6)*comp_mz, mz_upper = comp_mz+((QC4Metabolomics.env$target_cont$EIC_ppm)/1E6)*comp_mz) %>% # make mz interval for use for the EIC
                rownames_to_column(var="id") %>% mutate(id = as.factor(as.numeric(id))) %>% # need id for each row to group by. rowwise won't work
                group_by(id) %>% 
                get_EICs %>% 
                ungroup %>% 
                select(file, polarity, raw, path, comp_name, comp_mz, dplyr::contains("EIC")) %>% # contains have conflict with purrr
                filter(EIC_median>0) %>% # no reason to keep contaminants that were not found
                select(-raw,-EIC) # lets remove the big stuff so this could eventually go in a database
    
    
