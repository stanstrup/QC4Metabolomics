# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(readr)



# Establish connection -----------------------------------------------
pool <- dbPool(
                  drv = MySQL(),
                  dbname = MetabolomiQCsR.env$db$db,
                  host = MetabolomiQCsR.env$db$host,
                  username = MetabolomiQCsR.env$db$user,
                  password = MetabolomiQCsR.env$db$password,
                  idleTimeout = 30*60*1000 # 30 minutes.
)




# Get all tables ----------------------------------------------------------
dbs <- dbListTables(pool)

dir.create("backup", showWarnings = FALSE)

tables <- lapply(dbs, function(x)   dbReadTable(pool,x)   )

names(tables) <- dbs

# close connections
poolClose(pool)





# Zip the files -----------------------------------------------------------

save(  tables     , file = paste0("backup/",gsub(":","-",Sys.time()),".RData")    )
    


