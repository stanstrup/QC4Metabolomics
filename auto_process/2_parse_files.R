# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(dplyr)
library(magrittr)
#library(stringr)
library(tools)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(xml2)


# Vars --------------------------------------------------------------------
log_source = "2_parse_files.R"



# Establish connection to get new files -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# Get new files -----------------------------------------------------------
files <-  paste0("select path from new_files") %>% 
                                                    dbGetQuery(pool,.) %>% 
                                                    extract2("path")



# Parse filenames ---------------------------------------------------------

# Put in the log how many files we want to add to the queue
paste0("Will attempt to parse ",length(files)," new filenames") %>% 
    write_to_log(source = log_source, cat = "info", pool = pool)


# parse filename
file_tbl <- files %>% 
            sub("\\.[^.]*$", "", .) %>% 
            basename %>% 
    
            parse_filenames(MetabolomiQCsR.env$files$mask) %>% 
            as.tbl %>%
            mutate(path = files) %>% # we put back the original filenames with extension
            select(-filename) %>% 
            mutate_each(funs(as.numeric), batch_seq_nr, sample_ext_nr, inst_run_nr) %>% 
            mutate(time_filename = as.Date(date, MetabolomiQCsR.env$files$datemask) %>% format("%Y-%m-%d")) %>% # date format that mysql likes
            select(-date)
    



# lets check if the coersion caused invalid names
bad <- file_tbl %>% {rowSums(is.na(.)) > 0}

file_tbl %<>% mutate(FLAG = ifelse(bad,TRUE,FALSE))



# Does some have invalid file name?
if(any(file_tbl$FLAG)){
    
    file_tbl %>% 
        filter(FLAG) %>% 
        slice(1) %>% select(path) %>%
        paste0(sum(file_tbl$FLAG), " files had invalid filenames. First was: ",.,". They will be ignored. ") %>% 
        write_to_log(cat = "warning", source = log_source, pool = pool)
    
    
    file_tbl %<>% filter(!FLAG) %>% select(-FLAG)
    
}else{
  file_tbl %<>% select(-FLAG)  
}



# Do nothing if no new files
if(nrow(file_tbl)==0){
    write_to_log("No valid files to add to queue", cat = "info", source = log_source, pool = pool)
    
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}


            
# get mode from other field. Steno work-around
if(MetabolomiQCsR.env$files$mode_from_other_field){
   
  file_tbl %<>% mutate(mode = ifelse(
                                     grepl(MetabolomiQCsR.env$files$mode_from_other_field_pos_trigger, file_tbl %>% extract2(MetabolomiQCsR.env$files$mode_from_other_field_which) ),
                                     "pos",
                                     "unknown"
                                    )
                      )
    
  file_tbl %<>% mutate(mode = ifelse(
                                     grepl(MetabolomiQCsR.env$files$mode_from_other_field_neg_trigger, file_tbl %>% extract2(MetabolomiQCsR.env$files$mode_from_other_field_which) ),
                                     "neg",
                                     mode
                                )
                  )
}




# Get md5 of all files ----------------------------------------------------
poolClose(pool) # Close the connection because md5 can take a long time if there are many new files.

file_tbl %<>% mutate(file_md5 = path %>% as.character %>% paste0(MetabolomiQCsR.env$folders$base,"/",.) %>% normalizePath %>% md5sum %>% as.vector )



# Get run time from the XML data ------------------------------------------
file2time <- . %>%  
                    as.character %>% paste0(MetabolomiQCsR.env$folders$base,"/",.) %>% normalizePath %>% 
                    read_xml %>% 
                    xml_child(paste0(names(xml_ns(.)[1]),":mzML")) %>% 
                    xml_child(paste0(names(xml_ns(.)[1]),":run")) %>% 
                    xml_attr("startTimeStamp") %>% 
                    strptime("%Y-%m-%dT%H:%M:%SZ", tz="UTC") %>% 
                    format("%Y-%m-%d %H:%M:%S")

file2time <- Vectorize(file2time)

file_tbl %<>% mutate(time_run = file2time(path))



# Establish connection to write parsed files --------------------------------------------
pool <- dbPool_MetabolomiQCs(30)


# Add the files to new_files ----------------------------------------------

# write to the db
con <- poolCheckout(pool)

dbBegin(con)

res <- sqlAppendTable(con, "files", file_tbl) %>% 
       dbSendQuery(con,.)

res <- dbCommit(con)

poolReturn(con)

# Put in the log if db query successful
if(res){
    write_to_log("Added files to queue successfully", cat = "info", source = log_source, pool = pool) 
}else{
    write_to_log("Files were NOT added to the queue successfully", cat = "error", source = log_source, pool = pool) 
}


# remove files from new_files
con <- poolCheckout(pool)

dbBegin(con)

file_tbl %>% extract2("path") %>%  paste(collapse="','") %>% 
                                   paste0("'",.,"'") %>% 
                                   paste0("DELETE FROM new_files WHERE path IN (",.,")") %>% 
                                   dbSendQuery(con,.)

res <- dbCommit(con)

poolReturn(con)


# Put in the log if db query successful
if(res){
    write_to_log("Deleted parsed filesnames from new_files", cat = "info", source = log_source, pool = pool) 
}else{
    write_to_log("Could NOT delete parsed filesnames from new_files", cat = "error", source = log_source, pool = pool) 
}



# close connections
poolClose(pool)
