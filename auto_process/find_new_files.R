library(MetabolomiQCsR)
library(dplyr)
library(magrittr)
library(stringr)
library(DBI)
library(RMySQL)
   
 

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
include_path <- 
                MetabolomiQCsR.env$folders$include_path %>% 
                    strsplit(";",fixed=TRUE) %>% 
                    extract2(1) %>% 
                    paste(collapse="*", sep="") %>% 
                    paste0("*",.,"*") %>% 
                    glob2rx

files <- files[  grepl(files, pattern = include_path)   ]


# we don't need to do this with include_path since empty will match anything
if( str_trim(MetabolomiQCsR.env$folders$exclude_path) != "" ){
    exclude_path <- 
                    MetabolomiQCsR.env$folders$exclude_path %>% 
                        strsplit(";",fixed=TRUE) %>% 
                        extract2(1) %>% 
                        paste(collapse="|", sep="")
    
    files <- files[  !grepl(files,pattern = exclude_path)   ]   
}


# Put in the log how many files were found
message(paste0("Found ",length(files)," files.\n"))


# clean up
rm(search_pat, exclude_path, include_path)


# If no files found quit the process. Else do rest of script
if(length(files)==0) quit(save="no")



# Establish connection ----------------------------------------------------
con <- dbConnect(MySQL(),
                 user     = MetabolomiQCsR.env$db$user,
                 password = MetabolomiQCsR.env$db$password, 
                 host     = MetabolomiQCsR.env$db$host, 
                 dbname   = MetabolomiQCsR.env$db$db)


# Add the files new_files -------------------------------------------------
# figure if files are already in the new_files table (the queue to be processed)
files_already_in_db <-  paste(files,collapse="','") %>% 
                        paste0("'",.,"'") %>% 
                        paste0("select path from new_files where path in (",.,")") %>% 
                        dbGetQuery(con,.) %>% 
                        extract2("path")

# Only paths not already in the queue
files <- files[!(files %in% files_already_in_db)]


# figure if files are already in the files table (so already processed)
files_already_in_db <-  paste(files,collapse="','") %>% 
                        paste0("'",.,"'") %>% 
                        paste0("select path from files where path in (",.,")") %>% 
                        dbGetQuery(con,.) %>% 
                        extract2("path")

# Only paths not already in the queue
files <- files[!(files %in% files_already_in_db)]



# Do nothing if no new files
if(length(files)==0){
    message("No new files to add to queue.\n")
    
}else{
    
    # Put in the log how many files we want to add to the queue
    message(paste0("Will attempt to put ",length(files)," new files in the queue.\n"))
    
    
    # write to the db
    res <- sqlAppendTable(con, "new_files", data.frame(path=files)) %>% 
        dbSendQuery(con,.)
    
    res <- dbClearResult(res)
    
    # Put in the log if db query successful
    ifelse(res,"Added files to queue successfully.\n",
               "Files were NOT added to the queue successfully.\n"
    ) %>% 
    message

}


# close connections
dbDisconnect(con)
rm(res, con, files_already_in_db)

