#' Write message to QC4Metabolomics db
#'
#' @param idleTimeout The number of minutes that an idle object will be kept in the pool before it is destroyed.
#'
#' @return A \code{\link{dbPool}} object to connect to the MetabolomiQC database using settings in the ini file.
#' @export
#'
#' @keywords internal
#' 
#' @importFrom pool dbPool
#' @importFrom RMySQL MySQL
#' 
 
dbPool_MetabolomiQCs <- function(idleTimeout = 1){
  
  pool <- dbPool(
                  drv = MySQL(),
                  dbname = MetabolomiQCsR.env$db$db,
                  host = MetabolomiQCsR.env$db$host,
                  username = MetabolomiQCsR.env$db$user,
                  password = MetabolomiQCsR.env$db$password,
                  idleTimeout = idleTimeout*60*1000
                )
  
  return(pool)
  
}
  
  

#' Write message to QC4Metabolomics db
#'
#' @param msg The message. A character vector.
#' @param cat The category ("info", "warning" or "error"). A character vector.
#' @param pool (see pool package) to use for writing. If null a new connection will be made reading the connection details from the conf file.
#'
#' @return Nothing. Written to db.
#' @export
#'
#' @keywords internal
#' 
#' @importFrom pool dbPool poolCheckout poolReturn poolClose
#' @importFrom RMySQL MySQL
#' @importFrom DBI dbBegin dbCommit sqlAppendTable dbSendQuery
#' 

write_to_log <- function(msg, cat, source, pool = NULL){
    
    
    # put input in a table and get the date in the right format
    log_tbl <- data.frame(msg    = msg, 
                          cat    = cat,
                          source = source,
                          time   = format(Sys.time(), "%Y-%m-%d %X")
                          )
  
  
    # if the user didn't give is a pool we close it here.
    if(is.null(pool)) dbPool_MetabolomiQCs(5)
    
    
    
    # Write the data to to db
    con <- poolCheckout(pool)
    
    dbBegin(con)
    
    res <- sqlAppendTable(con, "log", log_tbl)
    res <- dbSendQuery(con,res)
    
    res <- dbCommit(con)
    
    poolReturn(con)
    
    
    # if we opened a new connection then close it again
    if(is.null(pool)){
        poolClose(pool)
    }
    
}




#' Remove files that no longer exist from the database
#'
#'
#' @param file_md5 A vector giving the md5 of the files to check.
#' @param path A vector giving the relative path to the files to check.
#' @param pool (see pool package) to use for writing. If null a new connection will be made reading the connection details from the conf file.
#' 
#' @return Database change and a logical vector saying which files existed.
#' @export
#'
#' @keywords internal
#' 
#' @importFrom tibble data_frame
#' @importFrom dplyr %>% mutate filter rowwise ungroup arrange select
#' @importFrom DBI dbListTables dbListFields dbBegin dbSendQuery dbCommit
#' @importFrom purrr map map_lgl map2_chr
#' @importFrom pool poolCheckout poolReturn
#' 
 


rem_dead_files <- function(file_md5, path, pool = NULL, log_source){
    
    # if the user didn't give is a pool we close it here.
    if(is.null(pool)) dbPool_MetabolomiQCs(5)
    
    
    file_tbl <- data_frame(file_md5 = file_md5, path = path) %>% 
                mutate(file_exists = path %>% as.character %>% paste0(MetabolomiQCsR.env$general$base,"/",.) %>% file.exists)
    
        
    if(any(!file_tbl$file_exists)){
     
        # get all tables that references files
        # also add a list of all files to remove
        tab_with_files <-   dbListTables(pool) %>% 
                            data_frame(table = .) %>% 
                            mutate(fields = map(table, ~ dbListFields(pool,.x))) %>% 
                            mutate(has_file_md5 = map_lgl(fields, ~ "file_md5" %in% .x)) %>% 
                            filter(has_file_md5) %>%
                            rowwise %>% 
                            mutate(file_md5 = list(as.character(file_tbl$file_md5[!file_tbl$file_exists]))) %>% 
                            ungroup
                            
        # make sql queries ready
        tab_with_files %<>% 
            mutate(sql = map2_chr(file_md5,table, ~ .x %>% paste(collapse="','") %>% paste0("'",.,"'") %>% paste0("DELETE FROM ",.y," WHERE file_md5 in (",.,")") ))
        
        # put the files table last to satisfy contraints
        tab_with_files %<>% 
            mutate(is_files_tab = table == "files") %>% 
            arrange(is_files_tab) %>% 
            select(-is_files_tab)
        
        
        # Do db query
        con <- poolCheckout(pool)
        dbBegin(con)
        
        res <- sapply(tab_with_files$sql, function(x){ dbSendQuery(con,x); dbCommit(con)})
        res <- unname(res)
        poolReturn(con)
        
        # write to log
        if(all(res)) write_to_log(paste0("Removed ",sum(!file_tbl$file_exists)," files that could not be found from the database"), cat = "warning", source = log_source, pool = pool)
        
    }
    
    return(file_tbl$file_exists)
}
