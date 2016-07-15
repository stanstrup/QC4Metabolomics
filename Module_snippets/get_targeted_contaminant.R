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
                mutate(comp_mz_lower = comp_mz-((QC4Metabolomics.env$target_cont$EIC_ppm/2)/1E6)*comp_mz, comp_mz_upper = comp_mz+((QC4Metabolomics.env$target_cont$EIC_ppm/2)/1E6)*comp_mz) %>% # make mz interval for use for the EIC
                rownames_to_column(var="id") %>% mutate(id = as.factor(as.numeric(id))) %>% # need id for each row to group by. rowwise won't work
                group_by(id) %>% 
                mutate(EIC   = pmap(list(raw,comp_mz_lower,comp_mz_upper),   function(raw,lower,upper) rawEIC(raw, as.matrix(data.frame(mzmin=lower,mzmax=upper)))   )) %>% # get the EICs
                mutate(EIC   = map(EIC,  ~ do.call(cbind.data.frame,.) %>% as.tbl  )) %>%     # EICs are lists. make nice data.frame
                mutate(EIC   = map2(EIC,raw, function(EIC,raw) mutate(EIC,scan_rt = raw@scantime[EIC$scan]/60)   )) %>% # convert scans to retention times
                mutate(EIC_median   = map_dbl(EIC,  ~ median(.$intensity)   )) %>%  # get the median intensity of each EIC
                mutate(EIC_mean     = map_dbl(EIC,  ~ mean(.$intensity)   )) %>%    # get the median intensity of each EIC
                mutate(EIC_sd       = map_dbl(EIC,  ~ sd(.$intensity)   )) %>%    # get the sd intensity of each EIC
                mutate(EIC_max      = map_dbl(EIC,  ~ max(.$intensity)   )) %>%     # get the max intensity of each EIC
                mutate(EIC_max      = map_dbl(EIC,  ~ max(.$intensity)   )) %>%     # get the max intensity of each EIC
                ungroup %>% 
                select(file, polarity, raw, path, comp_name, comp_mz, dplyr::contains("EIC")) %>% # contains have conflict with purrr
                filter(EIC_median>0) %>% # no reason to keep contaminants that were not found
                select(-raw,-EIC) # lets remove the big stuff so this could eventually go in a database
    
    
