library(MetabolomiQCsR)
library(dplyr)
library(magrittr)
library(stringr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
 

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
pool <- dbPool(
                  drv = MySQL(),
                  dbname = MetabolomiQCsR.env$db$db,
                  host = MetabolomiQCsR.env$db$host,
                  username = MetabolomiQCsR.env$db$user,
                  password = MetabolomiQCsR.env$db$password,
                  idleTimeout = 30*60*1000 # 30 minutes
)



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
    message("No new files to add to queue.\n")
    
    # close connections
    poolClose(pool)
    rm(pool, files_already_in_db)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}


# Add the files to new_files ----------------------------------------------

# Put in the log how many files we want to add to the queue
paste0("Will attempt to put ",length(files)," new files in the queue.\n") %>% 
    message


# parse filename
file_tbl <- files %>% 
            sub("\\.[^.]*$", "", .) %>% 
            basename %>% 
    
            parse_filenames(MetabolomiQCsR.env$files$mask) %>% 
            as.tbl %>%
            mutate(path = files) %>% # we put back the original filenames with extension
            select(-filename) %>% 
            mutate_each(funs(as.numeric), project_nr, batch_seq_nr, sample_ext_nr, inst_run_nr) %>% 
            mutate(date = as.Date(date, MetabolomiQCsR.env$files$datemask) %>% format("%Y-%m-%d")) # date format that mysql likes

            
# get mode from other field. Steno work-around
if(MetabolomiQCsR.env$files$mode_from_other_field){
   
  file_tbl %<>% mutate(mode = ifelse(
                                     grepl(MetabolomiQCsR.env$files$mode_from_other_field_pos_trigger, file_tbl %>% extract2(MetabolomiQCsR.env$files$mode_from_other_field_which) ),
                                     "pos",
                                     NA
                                    )
                      )
    
  file_tbl %<>% mutate(mode = ifelse(
                                     grepl(MetabolomiQCsR.env$files$mode_from_other_field_neg_trigger, file_tbl %>% extract2(MetabolomiQCsR.env$files$mode_from_other_field_which) ),
                                     "neg",
                                     mode
                                )
                  )
}





# write to the db
con <- poolCheckout(pool)

dbBegin(con)

res <- sqlAppendTable(con, "new_files", file_tbl) %>% 
       dbSendQuery(con,.)

res <- dbCommit(con)

poolReturn(con)

# Put in the log if db query successful
ifelse(res,
       "Added files to queue successfully.\n",
       "Files were NOT added to the queue successfully.\n"
      ) %>% 
message


# close connections
poolClose(pool)
rm(res, pool, con, files_already_in_db)
