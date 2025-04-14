# by standard sql ---------------------------------------------------------
# 
# sudo docker exec "qc4metabolomics-mariadb-1" mysqldump --user qc_db_user --password=qc_db_pw qc_db > /media/NyMetabolomics/Projects/QC_db_backup/2024-09-09.dump

# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(DBI)
library(RMySQL)
library(pool) # devtools::install_github("rstudio/pool")   
library(readr)



# Establish connection -----------------------------------------------
pool <- dbPool_MetabolomiQCs(30)

#out_dir <- "/data/QC_db_backup"
out_dir <-  "I:/SCIENCE-NEXS-NyMetabolomics/Projects/QC_db_backup"

# Get all tables ----------------------------------------------------------
dbs <- dbListTables(pool)

dir.create(out_dir, showWarnings = FALSE)

tables <- lapply(dbs, function(x)   dbReadTable(pool,x)   )

names(tables) <- dbs

# close connections
poolClose(pool)





# Zip the files -----------------------------------------------------------

save(  tables     , file = paste0(out_dir,"/",gsub(":","-",Sys.time()),".RData")    )
    


