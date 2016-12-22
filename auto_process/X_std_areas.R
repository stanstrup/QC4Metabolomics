library(xcms)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(magrittr)
library(MetabolomiQCsR)
library(purrr)
library(tidyr)
library(dplyr)


# TODO --------------------------------------------------------------------
# separate neg/pos # This should be in the controller FUN
# Decide which files need to be processed # This should be in the controller FUN
mode = "pos"



# Establish connection to get new files -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# Get data from db --------------------------------------------------------
# The selected files should only be the ones for the right mode
file_tbl <- dbReadTable(pool, "files") %>% 
            as.tbl %>% 
            mutate_each(funs(as.POSIXct(., tz="UTC")), time_filename, time_run) %>% 
            mutate_each(funs(as.factor), file_md5, project,instrument, mode)


std_compounds <- paste0("SELECT * from std_compounds WHERE mode=","'",mode,"'", "AND enabled=1",";") %>% 
                 dbGetQuery(pool,.) %>% 
                 as.tbl %>% 
                 mutate_each(funs(as.POSIXct(., tz="UTC")), updated_at) %>% 
                 mutate_each(funs(as.logical), enabled) %>% 
                 mutate_each(funs(as.factor), mode, cmp_name) %>% 
                 filter(enabled)



# Merge data --------------------------------------------------------------
std_compounds %>%   mutate_each(funs(.*60), cmp_rt1, cmp_rt2) %>% 
                    rename(rt=cmp_rt1, mz = cmp_mz) %>% # here we only support one rt atm

                    list %>% 
                    rep(nrow(file_tbl)) %>% 
                    data_frame(stds=.) %>% 
                    bind_cols(file_tbl,.) ->
file_stds_tbl




# Find peaks --------------------------------------------------------------
findPeaks_l <- lift_dl(findPeaks) # trick to make findPeaks accept a list of arguments.



file_stds_tbl %<>%
                  invoke_rows(.d= ., .f=function(path, stds, ...){
                                                                    raw <- path %>% as.character %>% paste0(MetabolomiQCsR.env$folders$base,"/",.) %>% normalizePath %>% 
                                                                           xcmsRaw(profparam = MetabolomiQCsR.env$xcmsRaw$profparam)
                                                                    
                                                                    ROI <- tbl2ROI(tbl    = stds, 
                                                                                   raw    = raw, 
                                                                                   ppm    = MetabolomiQCsR.env$findPeaks$ROI_ppm,
                                                                                   rt_tol = MetabolomiQCsR.env$std_match$rt_tol
                                                                                   )
                                                                    
                                                                    peaks <- findPeaks_l(MetabolomiQCsR.env$findPeaks %>% {.[which(names(.)!="ROI_ppm")]}, object = raw, ROI.list = ROI, mzdiff=0) %>% 
                                                                             as.data.frame %>% as.tbl
                                                                    
                                                                    EIC <- get_EICs(raw, data_frame(mz_lower = stds$mz - MetabolomiQCsR.env$findPeaks$ppm * stds$mz * 1E-6, 
                                                                                                    mz_upper = stds$mz + MetabolomiQCsR.env$findPeaks$ppm * stds$mz * 1E-6)
                                                                                    ) 
                                                                    
                                                                    # function to convert scan to rt
                                                                    scan2rt_fun <- approxfun(seq_along(raw@scantime),raw@scantime)
                                                                    
                                                                    data_frame(ROI = list(ROI), peaks = list(peaks), EIC = list(EIC), scan2rt_fun = list(scan2rt_fun)) %>% 
                                                                    return()
                                                                
                                                                },
                              .collate = "cols"
                             ) %>% 
                  rename(peaks = peaks1, EIC = EIC1, scan2rt_fun = scan2rt_fun1, ROI = ROI1)






# Find best matches -------------------------------------------------------
file_stds_tbl %<>% mutate(peaks = map(peaks, ~ mutate(.x, row = {if(nrow(.x)==0){integer(0)}else{1:nrow(.x)}}         ))) # we add a row index we can match by later
             
# apex mz
# The mass given my XCMS cannot be trusted with supplied ROIs
# need to get XCMS fixed.





file_stds_tbl %<>% mutate(peaks =     map2(stds, peaks, ~ closest_match(   .x, .y, 
                                                                           MetabolomiQCsR.env$std_match$rt_tol,
                                                                           MetabolomiQCsR.env$std_match$ppm
                                                                          ) %>% 
                                                            data_frame(row = .) %>% 
                                                            bind_cols(.x) %>% 
                                                            left_join(.y, by = "row", suffix = c(".stds", ".peaks")) %>% 
                                                            mutate(found = ifelse(is.na(row),FALSE,TRUE)) %>% 
                                                            select(-row)
                                          )
                         )



# Flattern ----------------------------------------------------------------
file_stds_tbl_flat <-    file_stds_tbl %>%
                         rename(mode.file = mode) %>% 
                         select(-EIC) %>% 
                         unnest(peaks, .drop = FALSE) %>% 
                         bind_cols(data_frame(EIC=unlist(file_stds_tbl$EIC,recursive = FALSE)))




# Additional peak stats ---------------------------------------------------
# rt and mz deviations
file_stds_tbl_flat %<>% mutate(mz_dev_ppm = ((mz.peaks - mz.stds)/mz.stds)*1E6 ) %>% 
                        mutate(rt_dev = rt.peaks - rt.stds , 
                               rt_dev_min = rt_dev/60
                               )


# FWHM
file_stds_tbl_flat %<>%    rowwise %>% 
                           mutate(FWHM_scan  = 2*sqrt(2*log(2))*sigma) %>% 
                           mutate(FWHM_start = (scpos - FWHM_scan/2) %>% scan2rt_fun ) %>%
                           mutate(FWHM_end   = (scpos + FWHM_scan/2) %>% scan2rt_fun ) %>% 
                           mutate(FWHM       =  FWHM_end - FWHM_start ) %>%
                           mutate(FWHM_dp    =  scmax - scmin + 1 ) %>% # data points
                           ungroup %>% 
                           select(-FWHM_scan, -FWHM_start, -FWHM_end)


# Tailing Factor and Assymmetry factor
file_stds_tbl_flat %>%   mutate(TF =  map2_dbl(EIC,rt.peaks, ~ peak_factor(.x,.y,factor="TF"))) %>% 
                         mutate(ASF = map2_dbl(EIC,rt.peaks, ~ peak_factor(.x,.y,factor="ASF")))


# Fill zeros when not found -----------------------------------------------





