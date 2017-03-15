# Establish connection to get new files -----------------------------------------------
log_source <- "TrackCmp"

pool <- dbPool_MetabolomiQCs(30)



# Do nothing if no compounds defined --------------------------------------
cmp_count <- paste0("SELECT COUNT(*) from std_compounds") %>% dbGetQuery(pool,.) %>% as.numeric

if(cmp_count==0){
    write_to_log("No compounds defined for TrackCmp to work on", cat = "info", source = log_source, pool = pool)
    
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}





# Get data ----------------------------------------------------------------
# check which columns we actually need
# priority = -1 means already
file_tbl <-  paste0("
                    SELECT file_schedule.*, file_info.time_run, project, mode, files.path
                    FROM file_schedule 
                    INNER JOIN files 
                    ON file_schedule.file_md5=files.file_md5
                    INNER JOIN file_info 
                    ON file_schedule.file_md5=file_info.file_md5
                    WHERE (file_schedule.module = 'module_TrackCmp' AND file_schedule.priority > 0)
                    ORDER BY file_schedule.priority ASC, file_info.time_run DESC
                    LIMIT 10
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            as.tbl %>% 
            mutate_each(funs(as.POSIXct(., tz="UTC")), time_run) %>% 
            mutate_each(funs(as.factor), file_md5, project, mode)


# Do nothing if nothing schedules
if(nrow(file_tbl)==0){
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}




std_compounds <- "SELECT * from std_compounds WHERE enabled=1" %>% 
                 dbGetQuery(pool,.) %>% 
                 as.tbl %>% 
                 mutate_each(funs(as.POSIXct(., tz="UTC")), updated_at) %>% 
                 mutate_each(funs(as.logical), enabled) %>% 
                 mutate_each(funs(as.factor), mode, cmp_name) %>% 
                 mutate_each(funs(.*60), cmp_rt1, cmp_rt2) %>% 
                 rename(rt=cmp_rt1, mz = cmp_mz) # here we only support one rt atm



# Joined data appropiately ------------------------------------------------
std_compounds_split <- split(std_compounds, std_compounds$mode)


file_stds_tbl <-  file_tbl %>% 
                  rowwise %>% 
                  mutate(stds =  switch(as.character(mode),
                                        pos = list(std_compounds_split$pos),
                                        neg = list(std_compounds_split$neg)
                                        )
                        ) %>% 
                  ungroup



# Find peaks --------------------------------------------------------------
findPeaks_l <- lift_dl(findPeaks) # trick to make findPeaks accept a list of arguments.



file_stds_tbl %<>%
                  invoke_rows(.d= ., .f=function(path, stds, ...){
                                                                    raw <- path %>% as.character %>% paste0(MetabolomiQCsR.env$general$base,"/",.) %>% normalizePath %>% 
                                                                           xcmsRaw(profparam = MetabolomiQCsR.env$TrackCmp$xcmsRaw$profparam)
                                                                    
                                                                    ROI <- tbl2ROI(tbl    = stds, 
                                                                                   raw    = raw, 
                                                                                   ppm    = MetabolomiQCsR.env$TrackCmp$ROI$ppm,
                                                                                   rt_tol = MetabolomiQCsR.env$TrackCmp$std_match$rt_tol
                                                                                   )
                                                                    
                                                                    peaks <- findPeaks_l(MetabolomiQCsR.env$TrackCmp$findPeaks, object = raw, ROI.list = ROI, mzdiff=0) %>% 
                                                                             as.data.frame %>% as.tbl
                                                                    
                                                                    EIC <- get_EICs(raw, data_frame(mz_lower = stds$mz - MetabolomiQCsR.env$TrackCmp$findPeaks$ppm * stds$mz * 1E-6, 
                                                                                                    mz_upper = stds$mz + MetabolomiQCsR.env$TrackCmp$findPeaks$ppm * stds$mz * 1E-6)
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
# The mass given by XCMS cannot be trusted with supplied ROIs
# need to get XCMS fixed.





file_stds_tbl %<>% mutate(peaks =     map2(stds, peaks, ~ closest_match(   .x, .y, 
                                                                           MetabolomiQCsR.env$TrackCmp$std_match$rt_tol,
                                                                           MetabolomiQCsR.env$TrackCmp$std_match$ppm
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
                        mutate_each(funs(./60),rt.stds, rt.peaks, rtmin, rtmax) %>% 
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
file_stds_tbl_flat %<>% mutate_each(funs(if_else(is.na(.),0,.)), into, intb, maxo,  FWHM, FWHM_dp)




# write to db -------------------------------------------------------------
std_stat_types <- dbReadTable(pool, "std_stat_types")
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
                        sqlAppendTable(pool, "std_stat_data", .) ->
sql_query
                        

sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE found = values(found), value = values(value)")

q_res <- sql_query %>% dbSendQuery(con, .)
row_updates <- dbGetRowsAffected(q_res)
res <- dbCommit(con)
poolReturn(con)

# write to log
if(res) write_to_log(paste0("Successfully asked to update statistics for ",file_stds_tbl_flat$file_md5 %>% nlevels," files. ",row_updates, " operations actually performed."), cat = "info", source = log_source, pool = pool)
if(!res) write_to_log(paste0("Failed to update statistics. Update was requested for ",file_stds_tbl_flat$file_md5 %>% nlevels," files."), cat = "error", source = log_source, pool = pool)




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






# close connections
poolClose(pool)

