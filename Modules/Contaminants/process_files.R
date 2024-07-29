get_raw_long <- function(raw){
as_tibble(peaksData(raw)) %>% 
    group_by(group) %>% 
    group_nest() %>% 
    bind_cols(scan_rt = rtime(raw),
              scan    =  scanIndex(raw)
             ) %>% 
   unnest(data) %>% 
   select(-group, -group_name)
}


extract_intervals <- function(raw, lower, upper, min_intensity = 1.2){
  
    raw_long <- get_raw_long(raw)
    
    raw_long_distinct_all <- raw_long %>% 
      distinct(scan, scan_rt)
    
    raw_long_distinct_all <- map_dfr(1:length(lower), ~ mutate(raw_long_distinct_all, idx = ..1))
    
    
    
    raw_long <-  raw_long %>%
      filter(intensity>=min_intensity) %>%
      filter(mz>min(lower), mz<max(upper))
    
    
    EICs_final <- raw_long %>% 
      left_join(
        tibble(idx = 1:length(lower), lower , upper),
        by = join_by(between(mz, lower, upper)),
        multiple = "all"
      ) %>% 
      filter(!is.na(idx)) %>% 
      group_by(idx, scan, scan_rt) %>% 
      summarise(intensity = max(intensity), .groups = "drop") %>% 
      full_join(raw_long_distinct_all, by = c("idx", "scan", "scan_rt")) %>% 
      mutate(intensity = if_else(is.na(intensity), 0, intensity)) %>% 
      arrange(scan) %>% 
      group_by(idx) %>% 
      group_nest() %>% 
      pull(data)

  return(EICs_final)
  
  
}

    

check_if_ms1 <- function(raw){
  
  msLevel(raw)
  
  
  if(  length(raw)>0  &&   length(msLevel(raw))>10   ){ # at least 10 scans to be meaningful
    return(TRUE)
  }else{
    return(FALSE)
  }
  
}


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
            as_tibble %>% 
            mutate(across(time_run, ~as.POSIXct(., tz="UTC"))) %>% 
            mutate(across(c(file_md5, project, mode), as.factor))



# Check if files still exist. ---------------------------------------------
dead_files <- rem_dead_files(file_md5 = file_tbl$file_md5, path = file_tbl$path, pool = pool, log_source = log_source)

file_tbl %<>% filter(dead_files)



# Get contaminants table --------------------------------------------------
data_cont <- dbReadTable(pool, "cont_cmp") %>% as_tibble %>% 
             mutate(mz_lower = mz-((MetabolomiQCsR.env$Contaminants$EIC_ppm )/1E6)*mz, mz_upper = mz+((MetabolomiQCsR.env$Contaminants$EIC_ppm )/1E6)*mz)



# Do nothing if nothing left is scheduled ---------------------------------
if(nrow(file_tbl)==0){
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}



# Joined data appropriately ------------------------------------------------
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




# loop through subsets of the files until all files are in the DB --------
file_tbl_std_l <- split(file_tbl_std, ceiling(1:nrow(file_tbl)/10))
file_tbl_std_l <- file_tbl_std_l[1:min(length(file_tbl_std_l),10)] # to avoid doing to many. # memory leak


for(ii in seq_along(file_tbl_std_l)){
    print("Starting next batch of files")
    
  
  
    file_tbl_std_l[[ii]] <- file_tbl_std_l[[ii]] %>%
                              mutate(raw = map(path, ~Spectra(paste0(MetabolomiQCsR.env$general$base,"/",..1))))
  
  

    # ignore files with no MS1
    file_tbl_std_l[[ii]] <- file_tbl_std_l[[ii]] %>% 
                              mutate(has_ms1 = map_lgl(raw,check_if_ms1))
    

    
    if(any(!file_tbl_std_l[[ii]]$has_ms1)){
        
        file_tbl_std_l[[ii]] %>% 
            filter(!has_ms1) %>% 
            slice(1) %>% select(path) %>%
            paste0(sum(file_tbl_std_l[[ii]]$has_ms1), " files did not contain any MS1 data or two few scans to be meaningful. First was: ",.,". They will be ignored.") %>% 
            write_to_log(cat = "warning", source = log_source, pool = pool)
        
      # Move to ignore list
      con <- poolCheckout(pool)
      dbBegin(con)
      
      # add
      res <- file_tbl_std_l[[ii]] %>%
        filter(!has_ms1) %>% 
        select(path, file_md5) %>% 
        sqlAppendTable(con, "files_ignore", .) %>% 
        dbSendQuery(con,.)
      
      res <- dbCommit(con)
      
      # remove
      md5del <- filter(file_tbl_std_l[[ii]], !has_ms1) %>% select(path, file_md5) %>% pull(file_md5)
      
      for(i in seq_along(md5del)){
        
        for(files_tables in c("file_info", "file_schedule", "files")){
          
          sql_query <- paste0("DELETE FROM ",files_tables," WHERE (file_md5='",md5del[i],"')")
          dbSendQuery(con,sql_query)
          dbCommit(con)
          
        }
        
      }
      
      poolReturn(con)
      
      
      
        
    file_tbl_std_l[[ii]] %<>% filter(has_ms1) %>% select(-has_ms1)
        
    }else{
      file_tbl_std_l[[ii]] %<>% select(-has_ms1)  
    }
    
    
  
    # Do nothing if nothing left
    if(nrow(file_tbl_std_l[[ii]])==0) next
    
  

  # Get EIC for all contaminants
  data_all <- file_tbl_std_l[[ii]] %>%
                    mutate(EIC = map2(raw,conts, ~extract_intervals(..1, ..2$mz_lower, ..2$mz_upper ))   )
    
    
  
    
    # put EIC and contaminants together
    data_all <- data_all %>% mutate(EIC = map2(EIC,conts, ~ bind_cols(.y, tibble(EIC = .x) ))) %>% 
                  select(-raw,-conts) %>% 
                  unnest(cols = c(EIC))
    
    
    # Summarize
    EIC_summary <-  data_all %>% 
                    select(file_md5, ion_id, EIC) %>% 
                    unnest(cols = c(EIC)) %>% 
                    group_by(file_md5, ion_id) %>% 
                    summarise(EIC_median = median(intensity), 
                              EIC_mean   = mean(intensity), 
                              EIC_sd     = sd(intensity), 
                              EIC_max    = max(intensity),
                              .groups = "drop"
                              ) %>% 
                    ungroup %>% 
                    gather(stat, value, -file_md5, -ion_id) %>% 
                    filter(value > 0)
    
    
    files_with_no_cont <- unique(data_all[(! data_all$file_md5 %in% EIC_summary$file_md5), "path", drop = TRUE]) %>% as.character
    
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


    # cleanup
    file_tbl_std_l[[ii]] <- file_tbl_std_l[[ii]] %>% select(-raw)
    rm(data_all)
    gc()
}


# close connections
poolClose(pool)
