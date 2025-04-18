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
                  dbname = Sys.getenv("MYSQL_DATABASE"),
                  host = Sys.getenv("MYSQL_HOST"),
                  username = Sys.getenv("MYSQL_USER"),
                  password = Sys.getenv("MYSQL_PASSWORD"),
                  port = as.numeric(Sys.getenv("MYSQL_PORT")),
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
                          time   = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
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
#' @importFrom tibble tibble
#' @importFrom dplyr %>% mutate filter rowwise ungroup arrange select
#' @importFrom DBI dbListTables dbListFields dbBegin dbSendQuery dbCommit
#' @importFrom purrr map map_lgl map2_chr
#' @importFrom pool poolCheckout poolReturn
#' 
 


rem_dead_files <- function(file_md5, path, pool = NULL, log_source){
    
    # make check happy
    has_file_md5 <- fields <- is_files_tab <- . <- NULL

    
    # if the user didn't give is a pool we close it here.
    if(is.null(pool)) dbPool_MetabolomiQCs(5)
    
    
    file_tbl <- tibble(file_md5 = file_md5, path = path) %>% 
                mutate(file_exists = path %>% as.character %>% paste0(Sys.getenv("QC4METABOLOMICS_base"),"/",.) %>% file.exists)
    
        
    if(any(!file_tbl$file_exists)){
     
        # get all tables that references files
        # also add a list of all files to remove
        tab_with_files <-   dbListTables(pool) %>% 
                            tibble(table = .) %>% 
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






#' Remove files that no longer exist from the database
#'
#'Return is a giving the dates corresponding to the last 
#'min_samples number of samples, but at least ALL samples from the last min_weeks weeks.
#'
#' @param min_weeks A vector saying the minimum number of weeks to return samples from.
#' @param min_samples A vector saying how many samples to minimum return. Always returns all samples from min_weeks period.
#' @param pool (see pool package) to use for writing. If null a new connection will be made reading the connection details from the conf file.
#' 
#' @return Named vector (min, max) with POSIXct times.
#' @export
#'
#' @keywords internal
#' 
#' @importFrom magrittr %>%
#' @importFrom DBI dbGetQuery
#' @importFrom lubridate weeks
#' 
 


default_time_range <- function(min_weeks=2, min_samples = 200, pool = NULL){

	dbGetQuery_sel_no_warn <- MetabolomiQCsR:::selectively_suppress_warnings(dbGetQuery, pattern = "unrecognized MySQL field type 7 in column 12 imported as character")

    # make check happy
    . <- NULL

    
    # if the user didn't give is a pool we close it here.
    if(is.null(pool)) dbPool_MetabolomiQCs(5)
    
    max <- "SELECT MAX(time_run) FROM file_info" %>% 
            dbGetQuery_sel_no_warn(pool,.) %>% 
            as.character %>% 
            as.POSIXct(format= "%Y-%m-%d %H:%M:%S")
    
    if(is.na(max)) return(NA)
    
    N <- {max-weeks(2)} %>% strftime("%Y-%m-%d %H:%M:%S") %>% 
          paste0("SELECT COUNT(time_run) FROM file_info WHERE time_run > '",.,"'") %>% 
          dbGetQuery_sel_no_warn(pool,.) %>% as.numeric
    
    
    if(N>200){
        
        min <- {max-weeks(min_weeks)}
        
    }else{
        
        min <- paste0("SELECT time_run FROM file_info ORDER BY time_run DESC LIMIT ",N-1, ",1") %>% 
            dbGetQuery_sel_no_warn(pool,.) %>% 
            as.character %>% 
            as.POSIXct(format= "%Y-%m-%d %H:%M:%S")
        
    }
    
    return(c(min=min, max=max))
                                    
}
