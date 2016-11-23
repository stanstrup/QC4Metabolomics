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
#' @param Pool (see pool package) to use for writing. If null a new connection will be made reading the connection details from the conf file.
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
