# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(readr)



# Establish connection -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)




# Get all tables ----------------------------------------------------------
dbs <- dbListTables(pool)

dir.create("backup", showWarnings = FALSE)

tables <- lapply(dbs, function(x)   dbReadTable(pool,x)   )

names(tables) <- dbs

# close connections
poolClose(pool)





# Zip the files -----------------------------------------------------------

save(  tables     , file = paste0("backup/",gsub(":","-",Sys.time()),".RData")    )
    


