# Establish connection to get new files -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)

log_source = "FileSchedule"


# Get new files -----------------------------------------------------------
new_files <-  "SELECT file_md5 FROM file_info WHERE file_md5 NOT IN (SELECT file_md5 FROM file_schedule)" %>% 
              dbGetQuery(pool,.)



# Do nothing if no new files
if(nrow(new_files)==0){
    write_to_log("No new files to add to file scheduler", cat = "info", source = log_source, pool = pool)
    
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}


enabled_modules <- get_QC4Metabolomics_settings() %>% 
                    filter(grepl("^QC4METABOLOMICS_.*_enabled$|QC4METABOLOMICS_.*_file_schedule$",name)) %>%
                    mutate(value = as.logical(value)) %>%
                    mutate(module = gsub("^QC4METABOLOMICS_module_(.*?)_.*$","\\1",name)) %>%
                    mutate(parameter = gsub("^QC4METABOLOMICS_module_.*?_(.*)$","\\1",name)) %>% 
                    pivot_wider(id_cols = module, names_from = "parameter", values_from = "value") %>% 
                    filter(file_schedule == TRUE & enabled == TRUE) %>% 
                    pull(module)


 new_files %<>% 
                  cbind(tibble(module = list(enabled_modules))) %>% 
                  unnest(module) %>% 
                  as_tibble %>% 
                  mutate(priority = 1L)


# Add the files to file_schedule ----------------------------------------------

# write to the db
con <- poolCheckout(pool)

dbBegin(con)

res <- new_files %>% 
       sqlAppendTable(con, "file_schedule", .) %>% 
       dbSendQuery(con,.)

res <- dbCommit(con)

poolReturn(con)

# Put in the log if db query successful
if(res){
    write_to_log(paste0("Added ", nrow(new_files)," files to file scheduler"), cat = "info", source = log_source, pool = pool) 
}else{
    write_to_log("Files were NOT added to the file scheduler", cat = "error", source = log_source, pool = pool) 
}



# close connections
poolClose(pool)
