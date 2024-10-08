# Vars --------------------------------------------------------------------
log_source = "Files"



# Get extension pattern ---------------------------------------------------
search_pat <- 
                as.character(Sys.getenv("QC4METABOLOMICS_module_Files_include_ext")) %>% 
                    strsplit(";",fixed=TRUE) %>% 
                    extract2(1) %>% 
                    paste("\\",.,"$", collapse="|", sep="")
    
    


# Get all files -----------------------------------------------------------
if(as.logical(Sys.getenv("QC4METABOLOMICS_module_Files_files_from_txt"))){
    
    if(!file.exists(as.character(Sys.getenv("QC4METABOLOMICS_module_Files_files_txt_path")))){quit(save="no")}
    
    files <- as.character(Sys.getenv("QC4METABOLOMICS_module_Files_files_txt_path")) %>% 
                readLines() %>% 
                grep(x=., pattern = search_pat, value = TRUE) %>% 
                gsub(paste0("^",Sys.getenv("QC4METABOLOMICS_base")), "", .)
    
}else{
files <- list.files(path= Sys.getenv("QC4METABOLOMICS_base"),
                    pattern = search_pat,
                    recursive = TRUE,
                    full.names = FALSE) # important for portability
}


# Apply include and exclude filters ---------------------------------------
# include
include_path <- 
                as.character(Sys.getenv("QC4METABOLOMICS_module_Files_include_path")) %>% 
                    strsplit(";",fixed=TRUE) %>% 
                    extract2(1) %>% 
                    paste(collapse="*", sep="") %>% 
                    paste0("*",.,"*") %>% 
                    glob2rx

files <- files[  grepl(files, pattern = include_path)   ]


# exclude
if( str_trim(as.character(Sys.getenv("QC4METABOLOMICS_module_Files_exclude_path"))) != "" ){ # we don't need to do this with include_path since empty will match anything
    exclude_path <- 
                    as.character(Sys.getenv("QC4METABOLOMICS_module_Files_exclude_path")) %>% 
                        strsplit(";",fixed=TRUE) %>% 
                        extract2(1) %>% 
                        paste(collapse="|", sep="")
    
    files <- files[  !grepl(files,pattern = exclude_path)   ]   
}


# normalize paths ---------------------------------------------------------

files <- normalizePath(files)


# Establish db connection -------------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# Log results -------------------------------------------------------------
# Put in the log how many files were found
paste0("Found ",length(files)," files") %>% 
    write_to_log(cat = "info", source = log_source, pool = pool)

# clean up
rm(search_pat, exclude_path, include_path)

# If no files found quit the process. Else do rest of script
if(length(files)==0){
    
    # close connections
    poolClose(pool)
    
    # quit
    quit(save="no")
}



# Figure if there are any new files to add to the db ----------------------
# we split the query in thousands to avoid errors.

# figure if files are already in the files table
q_fun <- . %>% 
            pull(files) %>% 
            paste(collapse="','") %>% 
            paste0("'",.,"'") %>% 
            paste0("select path from files where path in (",.,")") %>% 
            dbGetQuery(pool,.) %>%
            extract2("path")



files_already_in_db <- files %>% 
                        gsub("'","''",.) %>% 
                        tibble(files = .) %>%
                        mutate(n = (1:nrow(.) %/% 1000)) %>% 
                        nest(data = -n) %>% 
                        mutate(out = map(data, q_fun)) %>% 
                        select(out) %>% unnest(cols = out) %>% pull(out)


# Only paths not already in files
files <- files[!(files %in% files_already_in_db)]



if(length(files)==0 | all(is.na(files))){
    write_to_log("No new files to add to queue", source = log_source, cat = "info", pool = pool)
    
    # close connections
    poolClose(pool)
    rm(pool, files_already_in_db)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}



# Remove files in the ignore list -----------------------------------------

# If a file with same checksum is already in the db add new file to ignore list
# we split the query in thousands to avoid errors.
q_fun <- . %>% 
            pull(files) %>% 
            paste(collapse="','") %>% 
            paste0("'",.,"'") %>% 
            paste0("select path from files_ignore where path in (",.,")") %>% 
            dbGetQuery(pool,.) %>% 
            extract2("path")


ignored_files <- files %>% 
                    gsub("'","''",.) %>% 
                    tibble(files = .) %>%
                    mutate(n = (1:nrow(.) %/% 1000)) %>% 
                    nest(data = -n) %>% 
                    mutate(out = map(data, q_fun)) %>% 
                    select(out) %>% unnest(out) %>% pull(out)
            



ignored_files <- (files %in% ignored_files)
files <- files[!ignored_files]



# Remove non-existing files -----------------------------------------------
file_exists <- file.exists(paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",files))

files <- files[file_exists]



# Do nothing if no new files ----------------------------------------------
if(length(files)==0 | all(is.na(files))){
    write_to_log("No new files to add to queue", source = log_source, cat = "info", pool = pool)
    
    # close connections
    poolClose(pool)
    rm(pool, files_already_in_db)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}




# Take only 20 files at a time, write to db and do next -------------------
write_to_log(paste0(length(files), " new files to parse. Will take the newest 20 files at a time."), source = log_source, cat = "info", pool = pool)
# Close the connection because md5 can take a long time if there are many new files.
poolClose(pool)


# Get creation time
order <- files %>% as.character %>% paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",.) %>% file.info %>% extract2("ctime") %>% order(decreasing = TRUE)
files <- files[order]


# loop through subsets of the files until all files are in the DB
files_l <- split(files, ceiling(seq_along(files)/20))

for(i in seq_along(files_l)){
    
    # Get md5 of all files
    files_tab <- tibble(path = files_l[[i]]) %>% 
                 mutate(file_md5 = path %>% as.character %>% paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",.) %>% normalizePath %>% md5sum %>% as.vector )
    
    
    # Establish connection again
    pool <- dbPool_MetabolomiQCs(30)
    
    
    # If a file is already in the db with same MD5 add to ignore list
    md5_already_in_db <-    files_tab %>% extract2("file_md5") %>% 
                            paste(collapse="','") %>% 
                            paste0("'",.,"'") %>% 
                            paste0("select path, file_md5 from files where file_md5 in (",.,")") %>% 
                            dbGetQuery(pool,.) %>% 
                            extract2("file_md5")

    dup_md5 <- files_tab$file_md5 %in% md5_already_in_db
    
    if(any(dup_md5)){
        
        for(d in which(dup_md5)){
            
            write_to_log(paste0("A file identical to '",files_tab$path[d],"' is already in the database. Adding to ignore list."), cat = "warning", source = log_source, pool = pool) 
            
            con <- poolCheckout(pool)
            dbBegin(con)
            
            res <- files_tab %>% slice(d) %>% 
                sqlAppendTable(con, "files_ignore", .) %>% 
                dbSendQuery(con,.)
            
            res <- dbCommit(con)
            
            poolReturn(con)
            
        }
    }
    
    
    if(all(dup_md5)){
        poolClose(pool)
        next
    }
    
    
    files_tab %<>% filter(!(file_md5 %in% md5_already_in_db))
    
    
    # If several files in our batch has the same MD5 add the newest to the ignore list
    
    if(any(duplicated(files_tab$file_md5))){
     
        files_tab %<>% 
        mutate(file_date = path %>% paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",.) %>% file.info %>% extract2("ctime")) %>% 
        arrange(file_date) %>% 
        select(-file_date)
        
        
        # Take duplicated files and add to ignorelist
        files_tab %>% 
            filter(duplicated(file_md5) | duplicated(file_md5, fromLast = TRUE)) %>% 
            arrange(file_md5) %>% 
            extract2("path") %>% 
            paste(collapse=", ") %>% 
            paste0("The files ", . ," are identical (possibly in pairs). Adding newest to ignore list.") %>% 
            write_to_log(cat = "warning", source = log_source, pool = pool) 
            
            
            
            con <- poolCheckout(pool)
            dbBegin(con)
            
            res <- files_tab %>% 
                    filter(duplicated(file_md5)) %>% 
                    sqlAppendTable(con, "files_ignore", .) %>% 
                    dbSendQuery(con,.)
            
            res <- dbCommit(con)
            
            poolReturn(con)
           
        
        # take out files from the list before we proceed
        files_tab %<>% filter(!duplicated(file_md5))
        
        
    }
    
    
    
    
    
    # write to db was is left
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
