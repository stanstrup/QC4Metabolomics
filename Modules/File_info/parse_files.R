# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(dplyr)
library(magrittr)
#library(stringr)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(xml2)
library(purrr)
library(tidyr)


# Vars --------------------------------------------------------------------
log_source = "File_info"



# Funs --------------------------------------------------------------------
N_todo <- function(pool) {
                        "SELECT COUNT(*) FROM files WHERE file_md5 NOT IN (SELECT file_md5 FROM file_info)" %>%
                        dbGetQuery(pool,.) %>%
                        as.numeric
}


# Establish connection to get new files -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# We run until there is nothing left to do --------------------------------
while( N_todo(pool) != 0 ){
    
    
    # Get new files -----------------------------------------------------------
    # 20 newest files
    file_tbl <- "SELECT * FROM files WHERE file_md5 NOT IN (SELECT file_md5 FROM file_info)" %>% 
                dbGetQuery(pool,.) %>% as.tbl %>% 
                mutate(file_date = path %>% paste0(MetabolomiQCsR.env$general$base,"/",.) %>% file.info %>% extract2("ctime")) %>% 
                arrange(desc(file_date)) %>% 
                select(-file_date) %>% 
                slice(1:20)
    
    
    # Parse filenames ---------------------------------------------------------
    # Put in the log how many files we want to add to the queue
    paste0("Will attempt to parse ",nrow(file_tbl)," new filenames") %>% 
        write_to_log(source = log_source, cat = "info", pool = pool)
    
    
    # parse filename
    file_tbl <- file_tbl %>% 
                mutate(filename = sub("\\.[^.]*$", "", path)) %>% #remove extension
                mutate(filename = basename(filename)) %>%
        
                mutate(info = map(filename, ~ parse_filenames(.x, MetabolomiQCsR.env$module_File_info$mask))) %>%
                select(-filename) %>% 
                unnest(info)
        
    
    
    
    # lets check if the coersion caused invalid names in required fields
    if(MetabolomiQCsR.env$module_File_info$mode_from_other_field)  bad <- file_tbl %>% select(project, sample_id) %>% {rowSums(is.na(.)) > 0}
    if(!MetabolomiQCsR.env$module_File_info$mode_from_other_field) bad <- file_tbl %>% select(project, mode, sample_id) %>% {rowSums(is.na(.)) > 0}
    
    file_tbl %<>% mutate(FLAG = ifelse(bad,TRUE,FALSE))
    
    
    
    # Does some have invalid file name?
    if(any(file_tbl$FLAG)){
        
        file_tbl %>% 
            filter(FLAG) %>% 
            slice(1) %>% select(path) %>%
            paste0(sum(file_tbl$FLAG), " files had invalid filenames. First was: ",.,". They will be ignored. ") %>% 
            write_to_log(cat = "warning", source = log_source, pool = pool)
        
      # Move to ignore list
      con <- poolCheckout(pool)
      dbBegin(con)
      
      # add
      res <- file_tbl %>%
        filter(FLAG) %>% 
        select(path, file_md5) %>% 
        sqlAppendTable(con, "files_ignore", .) %>% 
        dbSendQuery(con,.)
      
      res <- dbCommit(con)
      
      # remove
      md5del <- filter(file_tbl, FLAG) %>% select(path, file_md5) %>% pull(file_md5)
      
      for(i in seq_along(md5del)){
        sql_query <- paste0("DELETE FROM files WHERE (file_md5='",md5del[i],"')")
        dbSendQuery(con,sql_query)
        dbCommit(con)
      }
      
      poolReturn(con)
      
      
      
        
    file_tbl %<>% filter(!FLAG) %>% select(-FLAG)
        
    }else{
      file_tbl %<>% select(-FLAG)  
    }
    
    
    
    # Do nothing if no new files
    if(nrow(file_tbl)==0){
        write_to_log("No valid files left in batch to add to queue", cat = "info", source = log_source, pool = pool)
        
      next
    }
    
    
                
    # get mode from other field. Steno work-around
    if(MetabolomiQCsR.env$module_File_info$mode_from_other_field){
       
      file_tbl %<>% mutate(mode = ifelse(
                                         grepl(MetabolomiQCsR.env$module_File_info$mode_from_other_field_pos_trigger, file_tbl %>% extract2(MetabolomiQCsR.env$module_File_info$mode_from_other_field_which) ),
                                         "pos",
                                         "unknown"
                                        )
                          )
        
      file_tbl %<>% mutate(mode = ifelse(
                                         grepl(MetabolomiQCsR.env$module_File_info$mode_from_other_field_neg_trigger, file_tbl %>% extract2(MetabolomiQCsR.env$module_File_info$mode_from_other_field_which) ),
                                         "neg",
                                         mode
                                    )
                      )
    }
    
    
    
    # Get run time from the XML data ------------------------------------------
    gc_pipe <- function(x){ gc();return(x)} # there seems to be a memory leak in the way I do it. So this will clean up after each file
    
    file2time <- . %>%  
                        as.character %>% paste0(MetabolomiQCsR.env$general$base,"/",.) %>% normalizePath %>% 
                        read_xml %>% 
                        xml_child(paste0(names(xml_ns(.)[1]),":mzML")) %>% 
                        xml_child(paste0(names(xml_ns(.)[1]),":run")) %>% 
                        xml_attr("startTimeStamp") %>% 
                        strptime("%Y-%m-%dT%H:%M:%SZ", tz="UTC") %>% 
                        format("%Y-%m-%d %H:%M:%S") %>% 
                        gc_pipe
    
    file2time <- Vectorize(file2time)
    
    file_tbl %<>% mutate(time_run = file2time(path))
    
    
    
    # Add the files to file_info  ----------------------------------------------
    
    # write to the db
    con <- poolCheckout(pool)
    
    dbBegin(con)
    
    res <- file_tbl %>% 
           select(file_md5, project, mode, sample_id, time_run) %>% 
           sqlAppendTable(con, "file_info", .) %>% 
           dbSendQuery(con,.)
    
    res <- dbCommit(con)
    
    poolReturn(con)
    
    # Put in the log if db query successful
    if(res){
        write_to_log("Added files to queue successfully", cat = "info", source = log_source, pool = pool) 
    }else{
        write_to_log("Files were NOT added to the queue successfully", cat = "error", source = log_source, pool = pool) 
    }
    
    
    

}


# close connections
poolClose(pool)
