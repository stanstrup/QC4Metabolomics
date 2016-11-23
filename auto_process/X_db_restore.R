# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(readr)


# File to restore ---------------------------------------------------------
file <- "2016-11-21 17-18-45.RData"



# Rebuild database --------------------------------------------------------
source("../setup/Create_db_tables.R", local = TRUE)



# Establish connection -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)


# Get restore-data --------------------------------------------------------
load(paste0("backup/",file))



# Get all tables ----------------------------------------------------------
dbs <- names(tables)



# Find tables with foreign keys -------------------------------------------
# not tested but I think tables with foreign keys need to go last.
foreign <- dbGetQuery(pool,"
                            select *
                            from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
                            where CONSTRAINT_TYPE = 'FOREIGN KEY'
                            "
                      )

foreign <- unique(foreign[,"TABLE_NAME"])

match <- match(foreign,dbs)

if(length(match)==0) match <- 1

dbs <- c(    dbs[-match], dbs[match]   )



# Replace tables ----------------------------------------------------------

for(i in seq_along(dbs)){
    
    if(nrow(tables[[dbs[i]]])==0) next
    
    
    con <- poolCheckout(pool)
    
    dbBegin(con)
    
    res <- res <- sqlAppendTable( pool, dbs[i], tables[[dbs[i]]]) %>% 
                  dbSendQuery(con,.)
    
    res <- dbCommit(con)
    
    poolReturn(con)
    
    
    if(res){
        message(paste0(dbs[i], " was successfully restored."))
    }else{
        message(paste0(dbs[i], "could not be restored."))
    }
    
    
}


# close connections -------------------------------------------------------
poolClose(pool)

