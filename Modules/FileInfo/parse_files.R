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
                        "SELECT COUNT(*) FROM files WHERE file_md5 NOT IN (SELECT file_md5 FROM file_info) AND file_md5 NOT IN (SELECT file_md5 FROM files_ignore)" %>%
                        dbGetQuery(pool,.) %>%
                        as.numeric
}




# Establish connection to get new files -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)



# We run until there is nothing left to do --------------------------------
while( N_todo(pool) != 0 ){
    
    
    # Get new files -----------------------------------------------------------
    # 20 newest files
    file_tbl <- "SELECT * FROM files WHERE file_md5 NOT IN (SELECT file_md5 FROM file_info) AND file_md5 NOT IN (SELECT file_md5 FROM files_ignore)" %>% 
                dbGetQuery(pool,.) %>% as_tibble %>% 
                mutate(file_date = path %>% paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",.) %>% file.info %>% extract2("ctime")) %>% 
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
        
                mutate(info = map(filename, ~ parse_filenames(.x, as.character(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mask"))))) %>%
                select(-filename) %>% 
                unnest(info)
    
    
    
        
    
    

    # invalid info (NAs) -----------------------------------------------------
    # lets check if the coersion caused invalid names in required fields
    if(as.logical(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mode_from_other_field")))  bad <- file_tbl %>% select(project, sample_id, instrument) %>% {rowSums(is.na(.)) > 0}
    if(!as.logical(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mode_from_other_field"))) bad <- file_tbl %>% select(project, mode, sample_id, instrument) %>% {rowSums(is.na(.)) > 0}
    
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
    if(as.logical(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mode_from_other_field"))){
       
      file_tbl %<>% mutate(mode = ifelse(
                                         grepl(as.character(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mode_from_other_field_pos_trigger")), file_tbl %>% extract2(as.character(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mode_from_other_field_which"))) ),
                                         "pos",
                                         "unknown"
                                        )
                          )
        
      file_tbl %<>% mutate(mode = ifelse(
                                         grepl(as.character(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mode_from_other_field_neg_trigger")), file_tbl %>% extract2(as.character(Sys.getenv("QC4METABOLOMICS_module_FileInfo_mode_from_other_field_which"))) ),
                                         "neg",
                                         mode
                                    )
                      )
    }
    
    


    # Invalid mode ------------------------------------------------------------
    # mode can only be 'pos','neg','unknown'
    
    # lets check if the coersion caused invalid modes
    file_tbl %<>% mutate(FLAG = ifelse(mode %in% c('pos','neg','unknown'),FALSE, TRUE))
    
    
    
    # Does some have invalid file name?
    if(any(file_tbl$FLAG)){
        
        file_tbl %>% 
            filter(FLAG) %>% 
            slice(1) %>% select(mode) %>%
            paste0(sum(file_tbl$FLAG), " files had invalid mode specification First was: ",.,". They will be ignored. ") %>% 
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
        
    
    


    
    # Get run time from the XML data ------------------------------------------
    file2time <- function(file, by_lines = 100L, max_rounds = 10L ) {
      
      path <- paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",file) %>% 
                  normalizePath
      
      round <- 1L
      output <- vector( mode = "character", length = 1 )
      out_round = ""
      while( !grepl( "startTimeStamp", output)  & round <= max_rounds ) {
        out_round <- readr::read_lines(path, skip = by_lines*(round-1), n_max =by_lines )
        output <- paste0(c(output, out_round), collapse="\n")
        round <- round + 1L
      }
      
      if(grepl( "startTimeStamp", output)){
      
      out <- gsub('.*startTimeStamp=\"(.*?)\".*', "\\1", output) %>% 
              strptime("%Y-%m-%dT%H:%M:%SZ", tz="UTC") %>% 
                format("%Y-%m-%d %H:%M:%S") 
      
      return(out)
        
      }else{
        return(NA)
      }
      
    }


    file2time <- Vectorize(file2time)
    
    file_tbl %<>% mutate(time_run = file2time(path))
    
    
    

    # If it could not get the file time add to ignore list --------------------

        if(any(is.na(file_tbl$time_run))){
        
        file_tbl %>% 
            filter(is.na(file_tbl$time_run)) %>% 
            slice(1) %>%
            {paste0(sum(is.na(file_tbl$time_run)), " files had missing run time. First was: ",.$filename,". They will be ignored. ")} %>% 
            write_to_log(cat = "warning", source = log_source, pool = pool)
        
      # Move to ignore list
      con <- poolCheckout(pool)
      dbBegin(con)
      
      # add
      res <- file_tbl %>%
        filter(is.na(time_run)) %>%
        select(path, file_md5) %>% 
        sqlAppendTable(con, "files_ignore", .) %>% 
        dbSendQuery(con,.)
      
      res <- dbCommit(con)
      
      # remove
      md5del <- file_tbl %>% filter(is.na(time_run)) %>% 
        #select(path, file_md5) %>% 
        pull(file_md5)
      
      for(i in seq_along(md5del)){
        sql_query <- paste0("DELETE FROM files WHERE (file_md5='",md5del[i],"')")
        dbSendQuery(con,sql_query)
        dbCommit(con)
      }
      
      poolReturn(con)
      
      
        
    file_tbl %<>% filter(!is.na(time_run))
        
    }
    
    
    
    # Do nothing if no new files
    if(nrow(file_tbl)==0){
        write_to_log("No valid files left in batch to add to queue", cat = "info", source = log_source, pool = pool)
        
      next
    }
        
    
    
    
    
    
    
    # Add the files to file_info  ----------------------------------------------
    
    # write to the db
    con <- poolCheckout(pool)
    
    dbBegin(con)
    
    res <- file_tbl %>% 
           select(file_md5, project, mode, sample_id, instrument, time_run) %>% 
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
