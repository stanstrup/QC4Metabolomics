# Establish connection to get new files -----------------------------------------------
log_source <- "Contaminants"

pool <- dbPool_MetabolomiQCs(30)


# Do nothing if no compounds defined --------------------------------------
cmp_count <- paste0("SELECT COUNT(*) from cont_cmp") %>% dbGetQuery(pool,.) %>% as.numeric

if(cmp_count==0){
    write_to_log("No compounds defined for Contaminants to work on", cat = "info", source = log_source, pool = pool)
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
                    SELECT file_schedule.*, file_info.time_run, project, mode, files.path
                    FROM file_schedule 
                    INNER JOIN files 
                    ON file_schedule.file_md5=files.file_md5
                    INNER JOIN file_info 
                    ON file_schedule.file_md5=file_info.file_md5
                    WHERE (file_schedule.module = 'module_Contaminants' AND file_schedule.priority > 0)
                    ORDER BY file_schedule.priority ASC, file_info.time_run DESC
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            as.tbl %>% 
            mutate_each(funs(as.POSIXct(., tz="UTC")), time_run) %>% 
            mutate_each(funs(as.factor), file_md5, project, mode)



# Check if files still exist. ---------------------------------------------
dead_files <- rem_dead_files(file_md5 = file_tbl$file_md5, path = file_tbl$path, pool = pool, log_source = log_source)

file_tbl %<>% filter(dead_files)



# Get contaminants table --------------------------------------------------
data_cont <- dbReadTable(pool, "cont_cmp") %>% as.tbl %>% 
             mutate(mz_lower = mz-((MetabolomiQCsR.env$Contaminants$EIC_ppm )/1E6)*mz, mz_upper = mz+((MetabolomiQCsR.env$Contaminants$EIC_ppm )/1E6)*mz)



# Do nothing if nothing left is scheduled ---------------------------------
if(nrow(file_tbl)==0){
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}



# Joined data appropiately ------------------------------------------------
data_cont_split <- split(data_cont, data_cont$mode)


file_tbl_std <-   file_tbl %>%
                  rowwise %>%
                  mutate(conts =  switch(as.character(mode),
                                        pos = list(data_cont_split$pos),
                                        neg = list(data_cont_split$neg)
                                        )
                        ) %>%
                  ungroup %>% 
                  select(-mode) # to avoid duplicate columns




# loop through subsets of the files untill all files are in the DB --------
file_tbl_std_l <- split(file_tbl_std, ceiling(1:nrow(file_tbl)/10))
file_tbl_std_l <- file_tbl_std_l[1:min(length(file_tbl_std_l),10)] # to avoid doing to many. # memory leak


for(ii in seq_along(file_tbl_std_l)){
    print("Starting next batch of files")
    
    # Read raw data
    data_all <- file_tbl_std_l[[ii]] %>%
                mutate(raw = map(path %>% as.character %>% paste0(MetabolomiQCsR.env$general$base,"/",.) %>% normalizePath, xcmsRaw, profstep = 0))
    
    # Get EIC for all contaminants
    data_all %<>%    mutate(   EIC = map2( raw, conts, get_EICs )   )
    
    # put EIC and contaminants together
    data_all %<>% mutate(EIC = map2(EIC,conts, ~ bind_cols(.y, data_frame(EIC = .x) ))) %>% 
                  select(-raw,-conts) %>% 
                  unnest
    
    
    # Summarize
    EIC_summary <-  data_all %>% 
                    select(file_md5, ion_id, EIC) %>% 
                    unnest %>% 
                    group_by(file_md5, ion_id) %>% 
                    summarise(EIC_median = median(intensity), 
                              EIC_mean   = mean(intensity), 
                              EIC_sd     = sd(intensity), 
                              EIC_max    = max(intensity)
                              ) %>% 
                    ungroup %>% 
                    gather(stat, value, -file_md5, -ion_id) %>% 
                    filter(value > 0)
    
    
    files_with_no_cont <- unique(data_all[(! data_all$file_md5 %in% EIC_summary$file_md5), "path"]) %>% as.character
    
    if(length(files_with_no_cont)!=0) write_to_log(paste0("No contaminant was found in: ", paste(files_with_no_cont, collapse=", ")), cat = "warning", source = log_source, pool = pool)
    
    
    res <- FALSE
    
    if(nrow(EIC_summary)!=0) {
        con <- poolCheckout(pool)
        dbBegin(con)
        
        sql_query <- EIC_summary %>%
                     sqlAppendTable(pool, "cont_data", .)
        
        sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE value = values(value)")
        
        q_res <- sql_query %>% dbSendQuery(con, .)
        row_updates <- dbGetRowsAffected(q_res)
        res <- dbCommit(con)
        poolReturn(con)
        
        # write to log
        if(res) write_to_log(paste0("Successfully asked to update statistics for ",EIC_summary$file_md5 %>% unique %>% length," files. ",row_updates, " operations actually performed."), cat = "info", source = log_source, pool = pool)
        if(!res) write_to_log(paste0("Failed to update statistics. Update was requested for ",file_stds_tbl_flat$file_md5 %>% unique %>% nlevels," files."), cat = "error", source = log_source, pool = pool)
        
    }
    
    
    # Update schedule
    if(res | length(files_with_no_cont)!=0){
        
        sql_data_non_missing <- data_all %>% 
            filter(!(path %in% files_with_no_cont)) %>% 
            distinct(file_md5) %>% 
            mutate(module = "module_Contaminants", priority = -1L)
        
        sql_data_missing <- data_all %>%
            filter(path %in% files_with_no_cont) %>% 
            distinct(file_md5) %>% 
            mutate(module = "module_Contaminants", priority = -1L)
        
        
        if(res & length(files_with_no_cont)!=0) sql_data  <- bind_rows(sql_data_non_missing, sql_data_missing)
        if(!res & length(files_with_no_cont)!=0) sql_data <- sql_data_missing
        if(res & length(files_with_no_cont)==0) sql_data  <- sql_data_non_missing
        
        
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


    
}


# close connections
poolClose(pool)
