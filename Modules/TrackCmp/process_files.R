# Establish connection to get new files -----------------------------------------------
log_source <- "TrackCmp"

pool <- dbPool_MetabolomiQCs(30)
std_stat_types <- dbReadTable(pool, "std_stat_types")


# Do nothing if no compounds defined --------------------------------------
cmp_count <- paste0("SELECT COUNT(*) from std_compounds") %>% dbGetQuery(pool,.) %>% as.numeric

if(cmp_count==0){
    write_to_log("No compounds defined for TrackCmp to work on", cat = "info", source = log_source, pool = pool)
    message("No compounds defined. Quitting.")
    
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}





# Get data ----------------------------------------------------------------
# check which columns we actually need
# priority = -1 means already
file_tbl <-  paste0("
                    SELECT file_schedule.*, file_info.time_run, project, instrument, mode, files.path
                    FROM file_schedule 
                    INNER JOIN files 
                    ON file_schedule.file_md5=files.file_md5
                    INNER JOIN file_info 
                    ON file_schedule.file_md5=file_info.file_md5
                    WHERE (file_schedule.module = 'module_TrackCmp' AND file_schedule.priority > 0)
                    ORDER BY file_schedule.priority ASC, file_info.time_run DESC
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            as_tibble %>% 
            mutate(across(time_run, ~as.POSIXct(., tz="UTC"))) %>% 
            mutate(across(c(file_md5, project, instrument, mode), as.factor))




# Check if any on ignore list ---------------------------------------------
ignored <-  paste0("
                    SELECT * FROM files_ignore
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble %>% 
            mutate(ignore = TRUE)

file_tbl <- 
  left_join(file_tbl, file_tbl, by = c("path", "file_md5")) %>%
  mutate(ignore = if_else(!is.na(ignore),ignore,FALSE)) %>% 
  filter(!ignore) %>% 
  select(-ignore)




# Check if files still exist. ---------------------------------------------
dead_files <- rem_dead_files(file_md5 = file_tbl$file_md5, path = file_tbl$path, pool = pool, log_source = log_source)

file_tbl %<>% filter(dead_files)


# Do nothing if nothing left is scheduled ---------------------------------
if(nrow(file_tbl)==0){
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}





# Get list of compounds ---------------------------------------------------
std_compounds <- "SELECT * from std_compounds WHERE enabled=1" %>% 
                 dbGetQuery(pool,.) %>% 
                 as_tibble %>% 
                 mutate(across(updated_at, ~as.POSIXct(., tz="UTC"))) %>% 
                 mutate(across(enabled, as.logical)) %>% 
                 mutate(across(c(mode, cmp_name, instrument), as.factor)) %>% 
                 mutate(across(c(cmp_rt1, cmp_rt2), ~(.*60))) %>% 
                 dplyr::rename(rt=cmp_rt1, mz = cmp_mz) # here we only support one rt atm




# loop through subsets of the files untill all files are in the DB --------
file_tbl_l <- split(file_tbl, ceiling(1:nrow(file_tbl)/10))
file_tbl_l <- file_tbl_l[1:pmin(10,length(file_tbl_l))] # to avoid doing to many. # memory leak


for(ii in seq_along(file_tbl_l)){
    print("Starting next batch of files")
    
    
    # Joined data appropiately ------------------------------------------------
  file_stds_tbl <- left_join(file_tbl_l[[ii]], std_compounds, by = c("instrument", "mode")) %>% 
                   nest(stds = c(cmp_id, cmp_name, mz, rt, cmp_rt2, enabled, updated_at)) %>% 
                   mutate(stds = pmap(list(stds, instrument, mode), ~mutate(..1, instrument=..2, mode = ..3)))
    
    
    
    # Set priority to -1 if no compounds defined for instrument/mode -------------------------
    
    to_ignore <- map_lgl(file_stds_tbl$stds, ~all(is.na(..1$mz)))
    
    
    # Update schedule
        sql_data <- file_stds_tbl %>% filter(to_ignore) %>% distinct(file_md5, module) %>% mutate(priority = -1L)
        
        con <- poolCheckout(pool)
        dbBegin(con)
        
        res_pri <- vector("logical", nrow(sql_data))
        for(i in 1:nrow(sql_data)){
            sql_query <- paste0("UPDATE file_schedule SET priority='", sql_data$priority[i],"' WHERE (file_md5='",sql_data$file_md5[i],"' AND module='",sql_data$module[i],"')")
            dbSendQuery(con,sql_query)
            res_pri[i] <- dbCommit(con)
        }
        
        poolReturn(con)
        write_to_log(paste0("priority updated for ",sum(res_pri)," files."), cat = "info", source = log_source, pool = pool)
    
    
    # remove from current queue
    file_stds_tbl %<>% filter(!to_ignore)
    
    
    
    
    
    
    
    
    
    
    # ignore files with no MS1
    file_stds_tbl <- file_stds_tbl %>% 
            mutate(has_ms1 = map_lgl(path, ~ any(1 == unique(fData(readMSData(paste0(MetabolomiQCsR.env$general$base,"/",.), mode = "onDisk"))[, "msLevel"]))))
    
    
    
    if(any(!file_stds_tbl$has_ms1)){
        
        file_stds_tbl %>% 
            filter(!has_ms1) %>% 
            slice(1) %>% select(path) %>%
            paste0(sum(file_stds_tbl$has_ms1), " files did not contain any MS1 data. First was: ",.,". They will be ignored.") %>% 
            write_to_log(cat = "warning", source = log_source, pool = pool)
        
      # Move to ignore list
      con <- poolCheckout(pool)
      dbBegin(con)
      
      # add
      res <- file_stds_tbl %>%
        filter(!has_ms1) %>% 
        select(path, file_md5) %>% 
        sqlAppendTable(con, "files_ignore", .) %>% 
        dbSendQuery(con,.)
      
      res <- dbCommit(con)
      
      # remove
      md5del <- filter(file_stds_tbl, !has_ms1) %>% select(path, file_md5) %>% pull(file_md5)
      
      for(i in seq_along(md5del)){
        
        for(files_tables in c("file_info", "file_schedule", "files")){
          
          sql_query <- paste0("DELETE FROM ",files_tables," WHERE (file_md5='",md5del[i],"')")
          dbSendQuery(con,sql_query)
          dbCommit(con)
          
        }
        
      }
      
      poolReturn(con)
      
      
      
        
    file_stds_tbl %<>% filter(has_ms1) %>% select(-has_ms1)
        
    }else{
      file_stds_tbl %<>% select(-has_ms1)  
    }
    
    
    

    
    
    
    # Do nothing if nothing left
    if(nrow(file_stds_tbl)==0) next
    
    
    # Find peaks --------------------------------------------------------------
    findPeaks_l <- lift_dl(findPeaks) # trick to make findPeaks accept a list of arguments.
    
    
    
    file_stds_tbl %<>% mutate(out = 
                    							  map2(path, stds, function(a,b) {
                    																				raw <- a %>% 
                          																				  as.character %>% 
                          																				  paste0(MetabolomiQCsR.env$general$base,"/",.) %>% 
                          																				  normalizePath %>% 
                          																					xcmsRaw(profparam = MetabolomiQCsR.env$TrackCmp$xcmsRaw$profparam)
                    																				
                    																				ROI <- tbl2ROI(tbl    = b,
                          																							   raw    = raw,
                          																							   ppm    = MetabolomiQCsR.env$TrackCmp$ROI$ppm,
                          																							   rt_tol = MetabolomiQCsR.env$TrackCmp$std_match$rt_tol
                          																							   )
                    # 																				
                    																				peaks <- findPeaks_l(MetabolomiQCsR.env$TrackCmp$findPeaks, object = raw, ROI.list = ROI, mzdiff=0, mzCenterFun = "apex") %>%
                    																						      as.data.frame %>%
                    																				          as_tibble
# 
                    																				EIC <- get_EICs(raw, tibble(mz_lower = b$mz - MetabolomiQCsR.env$TrackCmp$findPeaks$ppm * b$mz * 1E-6,
                    																												            mz_upper = b$mz + MetabolomiQCsR.env$TrackCmp$findPeaks$ppm * b$mz * 1E-6
                    																												            )
                    																								        )
                    # 																				
                    # 																				# function to convert scan to rt
                    																				scan2rt_fun <- approxfun(seq_along(raw@scantime),raw@scantime)

                    																				tibble(ROI = list(ROI), peaks = list(peaks), EIC = list(EIC), scan2rt_fun = list(scan2rt_fun)) %>%
                    																				return()
                    																			
                    												           }
                    										 ) 
                    							  ) %>% 
                                          unnest(out)
    
    
    
    
    
    
    # Find best matches -------------------------------------------------------
    file_stds_tbl %<>% mutate(peaks = map(peaks, ~ mutate(.x, row = {if(nrow(.x)==0){integer(0)}else{1:nrow(.x)}}  ))) # we add a row index we can match by later
                 
    # apex mz
    # The mass given by XCMS cannot be trusted with supplied ROIs
    # need to get XCMS fixed.
    
    
    
    
    
    file_stds_tbl %<>% mutate(peaks =     map2(stds, peaks, ~ closest_match(   .x, .y, 
                                                                               MetabolomiQCsR.env$TrackCmp$std_match$rt_tol,
                                                                               MetabolomiQCsR.env$TrackCmp$std_match$ppm
                                                                              ) %>% 
                                                                tibble(row = .) %>% 
                                                                bind_cols(.x) %>% 
                                                                left_join(.y, by = "row", suffix = c(".stds", ".peaks")) %>% 
                                                                mutate(found = ifelse(is.na(row),FALSE,TRUE)) %>% 
                                                                select(-row)
                                              )
                             )
    
    
    
    # Flattern ----------------------------------------------------------------
    file_stds_tbl_flat <-    file_stds_tbl %>%
                             dplyr::rename(mode.file = mode) %>% 
                             select(-EIC, -stds, -ROI, -instrument ) %>% 
                             unnest(peaks) %>% 
                             bind_cols(tibble(EIC=unlist(file_stds_tbl$EIC,recursive = FALSE)))
    
    # try to avoid memory leak
    rm(file_stds_tbl)
    gc()
    
    
    # Additional peak stats ---------------------------------------------------
    # rt and mz deviations
    file_stds_tbl_flat %<>% mutate(mz_dev_ppm = ((mz.peaks - mz.stds)/mz.stds)*1E6 ) %>% 
                            mutate(across(c(rt.stds, rt.peaks, rtmin, rtmax), ~(./60))) %>% 
                            mutate(rt_dev = rt.peaks - rt.stds)
    
    
    # FWHM
    file_stds_tbl_flat %<>%    rowwise %>% 
                               mutate(FWHM_scan  = 2*sqrt(2*log(2))*sigma) %>% 
                               mutate(FWHM_start = (scpos - FWHM_scan/2) %>% scan2rt_fun, FWHM_start = FWHM_start/60 ) %>%
                               mutate(FWHM_end   = (scpos + FWHM_scan/2) %>% scan2rt_fun, FWHM_end = FWHM_end/60 ) %>% 
                               mutate(FWHM       =  FWHM_end - FWHM_start ) %>%
                               mutate(FWHM_dp    =  scmax - scmin + 1 ) %>% # data points
                               ungroup %>% 
                               select(-FWHM_scan, -FWHM_start, -FWHM_end)
    
    
    # Tailing Factor and Assymmetry factor
    file_stds_tbl_flat %<>%  mutate(TF =  map2_dbl(EIC,rt.peaks, ~ peak_factor(.x,.y,factor="TF"))) %>% 
                             mutate(ASF = map2_dbl(EIC,rt.peaks, ~ peak_factor(.x,.y,factor="ASF")))
    
    
    
    # Fill zeros when not found -----------------------------------------------
    file_stds_tbl_flat %<>% mutate(across(c(into, intb, maxo,  FWHM, FWHM_dp), ~if_else(is.na(.),0,as.numeric(.))))
    
    
    
    
    # write to db -------------------------------------------------------------
    con <- poolCheckout(pool)
    dbBegin(con)
    
    
    file_stds_tbl_flat %>% select(file_md5, cmp_id, found,
                                  mz = mz.peaks, mzmin, mzmax, 
                                  rt = rt.peaks, rtmin, rtmax, 
                                  into, intb, maxo, 
                                  sn, egauss, mu, sigma, h, f, 
                                  mz_dev_ppm, rt_dev, FWHM, datapoints = FWHM_dp,
                                  TF, ASF
                                  ) %>% 
                            gather(stat_name, value, -file_md5, -cmp_id, -found) %>% 
                            left_join(std_stat_types, by="stat_name") %>% 
                            select(file_md5, stat_id, cmp_id, found, value) %>% 
                            mutate(value = if_else(is.nan(value), NA_real_, value)) %>% 
                            sqlAppendTable(pool, "std_stat_data", .) ->
    sql_query
                            
    
    sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE found = values(found), value = values(value)")
    
    q_res <- sql_query %>% dbSendQuery(con, .)
    row_updates <- dbGetRowsAffected(q_res)
    res <- dbCommit(con)
    poolReturn(con)
    
    # write to log
    if(res) write_to_log(paste0("Successfully asked to update statistics for ",file_stds_tbl_flat$file_md5 %>% unique %>% length," files. ",row_updates, " operations actually performed."), cat = "info", source = log_source, pool = pool)
    if(!res) write_to_log(paste0("Failed to update statistics. Update was requested for ",file_stds_tbl_flat$file_md5 %>% unique %>% length," files."), cat = "error", source = log_source, pool = pool)
    
    
    
    
    # Update schedule
    if(res){
        
        sql_data <- file_stds_tbl_flat %>% distinct(file_md5, module) %>% mutate(priority = -1L)
        
        con <- poolCheckout(pool)
        dbBegin(con)
        
        res_pri <- vector("logical", nrow(sql_data))
        for(i in 1:nrow(sql_data)){
            sql_query <- paste0("UPDATE file_schedule SET priority='", sql_data$priority[i],"' WHERE (file_md5='",sql_data$file_md5[i],"' AND module='",sql_data$module[i],"')")
            dbSendQuery(con,sql_query)
            res_pri[i] <- dbCommit(con)
        }
        
        
        poolReturn(con)
        write_to_log(paste0("priority updated for ",sum(res_pri)," files."), cat = "info", source = log_source, pool = pool)
    }

    # try to avoid memory leak
    rm(file_stds_tbl_flat)
    gc()
}



# close connections
poolClose(pool)

