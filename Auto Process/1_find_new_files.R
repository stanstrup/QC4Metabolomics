# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(dplyr)
library(magrittr)
library(stringr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   

 

# Vars --------------------------------------------------------------------
log_source = "1_find_new_files.R"



# Get extension pattern ---------------------------------------------------
search_pat <- 
                MetabolomiQCsR.env$folders$include_ext %>% 
                    strsplit(";",fixed=TRUE) %>% 
                    extract2(1) %>% 
                    paste("\\",.,"$", collapse="|", sep="")
    
    

# Get all files -----------------------------------------------------------
files <- list.files(path= MetabolomiQCsR.env$folders$base,
                    pattern = search_pat,
                    recursive = TRUE,
                    full.names = FALSE) # important for portability



# Apply include and exclude filters ---------------------------------------
# include
include_path <- 
                MetabolomiQCsR.env$folders$include_path %>% 
                    strsplit(";",fixed=TRUE) %>% 
                    extract2(1) %>% 
                    paste(collapse="*", sep="") %>% 
                    paste0("*",.,"*") %>% 
                    glob2rx

files <- files[  grepl(files, pattern = include_path)   ]


# exclude
if( str_trim(MetabolomiQCsR.env$folders$exclude_path) != "" ){ # we don't need to do this with include_path since empty will match anything
    exclude_path <- 
                    MetabolomiQCsR.env$folders$exclude_path %>% 
                        strsplit(";",fixed=TRUE) %>% 
                        extract2(1) %>% 
                        paste(collapse="|", sep="")
    
    files <- files[  !grepl(files,pattern = exclude_path)   ]   
}



# Establish connection ----------------------------------------------------
pool <- dbPool_MetabolomiQCs(30)


# Log results -------------------------------------------------------------
# Put in the log how many files were found
paste0("Found ",length(files)," files") %>% 
    write_to_log(cat = "info", source = log_source, pool = pool)

# clean up
rm(search_pat, exclude_path, include_path)

# If no files found quit the process. Else do rest of script
if(length(files)==0) quit(save="no")




# Figure if there are any new files to add to the queue -------------------

# figure if files are already in the new_files table (the queue to be processed)
files_already_in_db <-  paste(files,collapse="','") %>% 
                        paste0("'",.,"'") %>% 
                        paste0("select path from new_files where path in (",.,")") %>% 
                        dbGetQuery(pool,.) %>% 
                        extract2("path")

# Only paths not already in the queue (new_files table)
files <- files[!(files %in% files_already_in_db)]

# figure if files are already in the files table (so already processed)
files_already_in_db <-  paste(files,collapse="','") %>% 
                        paste0("'",.,"'") %>% 
                        paste0("select path from files where path in (",.,")") %>% 
                        dbGetQuery(pool,.) %>% 
                        extract2("path")

# Only paths not already in the files table
files <- files[!(files %in% files_already_in_db)]



# Do nothing if no new files
if(length(files)==0){
    write_to_log("No new files to add to queue", source = log_source, cat = "info", pool = pool)
    
    # close connections
    poolClose(pool)
    rm(pool, files_already_in_db)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}



# Write to db -------------------------------------------------------------

con <- poolCheckout(pool)

dbBegin(con)

res <- sqlAppendTable(con, "new_files", data_frame(path = files)) %>% 
       dbSendQuery(con,.)

res <- dbCommit(con)

poolReturn(con)

# Put in the log if db query successful

if(res){
    write_to_log("Added files to queue successfully", cat = "info", source = log_source, pool = pool) 
}else{
    write_to_log("Files were NOT added to the queue successfully", cat = "error", source = log_source, pool = pool) 
}



# close connections
poolClose(pool)
