# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(readr)


# File to restore ---------------------------------------------------------
file <- "2016-11-21 17-18-45.RData"



# Establish connection -----------------------------------------------
pool <- dbPool(
                  drv = MySQL(),
                  dbname = MetabolomiQCsR.env$db$db,
                  host = MetabolomiQCsR.env$db$host,
                  username = MetabolomiQCsR.env$db$user,
                  password = MetabolomiQCsR.env$db$password,
                  idleTimeout = 30*60*1000 # 30 minutes.
)


# Get restore-data --------------------------------------------------------
load(paste0("backup/",file))





# Get all tables ----------------------------------------------------------
dbs <- names(tables)



# Find tables with foreign keys -------------------------------------------

foreign <- dbGetQuery(pool,"
                            select *
                            from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
                            where CONSTRAINT_TYPE = 'FOREIGN KEY'
                            "
                      )

foreign <- unique(foreign[,"TABLE_NAME"])

match <- match(foreign,dbs)

if(length(match)==0) match <- 1

dbs <- c(    dbs[match], dbs[-match]   )



# Replace tables ----------------------------------------------------------

for(i in seq_along(dbs)){
    
    res <- dbRemoveTable(pool, dbs[i]) 
    
    if(res){
        message(paste0(dbs[i], " was successfully removed."))
    }else{
        message(paste0(dbs[i], "could not be removed."))
    }
    
    res <- dbWriteTable( pool, dbs[i], tables[[dbs[i]]])
    
        if(res){
        message(paste0(dbs[i], " was successfully restored."))
    }else{
        message(paste0(dbs[i], "could not be restored."))
    }
    
    
}


# close connections -------------------------------------------------------
poolClose(pool)


