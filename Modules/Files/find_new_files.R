# Vars --------------------------------------------------------------------
log_source = "Files"



# Get extension pattern ---------------------------------------------------
search_pat <- 
                MetabolomiQCsR.env$module_Files$include_ext %>% 
                    strsplit(";",fixed=TRUE) %>% 
                    extract2(1) %>% 
                    paste("\\",.,"$", collapse="|", sep="")
    
    

# Get all files -----------------------------------------------------------
files <- list.files(path= MetabolomiQCsR.env$general$base,
                    pattern = search_pat,
                    recursive = TRUE,
                    full.names = FALSE) # important for portability



# Apply include and exclude filters ---------------------------------------
# include
include_path <- 
                MetabolomiQCsR.env$module_Files$include_path %>% 
                    strsplit(";",fixed=TRUE) %>% 
                    extract2(1) %>% 
                    paste(collapse="*", sep="") %>% 
                    paste0("*",.,"*") %>% 
                    glob2rx

files <- files[  grepl(files, pattern = include_path)   ]


# exclude
if( str_trim(MetabolomiQCsR.env$module_Files$exclude_path) != "" ){ # we don't need to do this with include_path since empty will match anything
    exclude_path <- 
                    MetabolomiQCsR.env$module_Files$exclude_path %>% 
                        strsplit(";",fixed=TRUE) %>% 
                        extract2(1) %>% 
                        paste(collapse="|", sep="")
    
    files <- files[  !grepl(files,pattern = exclude_path)   ]   
}




# Establish db connection -------------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# Log results -------------------------------------------------------------
# Put in the log how many files were found
paste0("Found ",length(files)," files") %>% 
    write_to_log(cat = "info", source = log_source, pool = pool)

# clean up
rm(search_pat, exclude_path, include_path)

# If no files found quit the process. Else do rest of script
if(length(files)==0) quit(save="no")



# Figure if there are any new files to add to the db ----------------------

# figure if files are already in the files table
files_already_in_db <-  paste(files,collapse="','") %>% 
                        paste0("'",.,"'") %>% 
                        paste0("select path from files where path in (",.,")") %>% 
                        dbGetQuery(pool,.) %>% 
                        extract2("path")

# Only paths not already in files
files <- files[!(files %in% files_already_in_db)]



# Do nothing if no new files ----------------------------------------------
if(length(files)==0){
    write_to_log("No new files to add to queue", source = log_source, cat = "info", pool = pool)
    
    # close connections
    poolClose(pool)
    rm(pool, files_already_in_db)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}




# Take only 20 files at a time, write to db and do next -------------------
write_to_log(paste0(length(files), " New files to parse. Will take the newest 20 files at a time."), source = log_source, cat = "info", pool = pool)
# Close the connection because md5 can take a long time if there are many new files.
poolClose(pool)



# Get creation time
order <- files %>% as.character %>% paste0(MetabolomiQCsR.env$general$base,"/",.) %>% file.info %>% extract2("ctime") %>% order(decreasing = TRUE)
files <- files[order]

files_l <- split(files, ceiling(seq_along(files)/20))



for(i in seq_along(files_l)){
    
    # Get md5 of all files
    files_tab <- data_frame(path = files_l[[i]]) %>% 
                 mutate(file_md5 = path %>% as.character %>% paste0(MetabolomiQCsR.env$general$base,"/",.) %>% normalizePath %>% md5sum %>% as.vector )
    
    
    # Write to db
    # Establish connection again
    pool <- dbPool_MetabolomiQCs(30)
    
    
    
    # If a file with same checksum is already in the db ignore the new file
    # this can happen if there is a copy of a file
    md5_already_in_db <-    files_tab %>% extract2("file_md5") %>% 
                            paste(collapse="','") %>% 
                            paste0("'",.,"'") %>% 
                            paste0("select path, file_md5 from files where file_md5 in (",.,")") %>% 
                            dbGetQuery(pool,.) %>% 
                            extract2("file_md5")
    
    
    dup_md5 <- files_tab$file_md5 %in% md5_already_in_db
    
    if(any(dup_md5)){
        for(d in which(dup_md5)){
    write_to_log(paste0("A file identical to '",files_tab$path[d],"' is already in the database. Skipping."), cat = "warning", source = log_source, pool = pool) 
        }
    }
    
    files_tab %<>% filter(!(file_md5 %in% md5_already_in_db))
    
    # write to db
    con <- poolCheckout(pool)
    dbBegin(con)
    
    res <- files_tab %>% 
           sqlAppendTable(con, "files", .) %>% 
           dbSendQuery(con,.)
    
    res <- dbCommit(con)
    
    poolReturn(con)
    
    
    # Put in the log if db query successful
    if(res){
        write_to_log(paste0("Added ",length(files_l[[i]])," files to queue successfully"), cat = "info", source = log_source, pool = pool) 
    }else{
        write_to_log("Files were NOT added to the queue successfully", cat = "error", source = log_source, pool = pool) 
    }
    
    
    
    # close connections
    poolClose(pool)

}
