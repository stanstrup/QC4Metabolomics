# Libraries ---------------------------------------------------------------
library(MetabolomiQCsR)
library(dplyr)
library(magrittr)
library(DBI)
library(RMySQL)
  

# Establish connection ----------------------------------------------------
con <- dbConnect(MySQL(),
                 user     = MetabolomiQCsR.env$db$user,
                 password = MetabolomiQCsR.env$db$password, 
                 host     = MetabolomiQCsR.env$db$host, 
                 dbname   = MetabolomiQCsR.env$db$db)



# Figure if there are new files -------------------------------------------
# complicated query to check if there are files in "files" that are not processed
# if not quit
# if one stat has been done but not another note in log

#file_md5 <- paste0("SELECT * from files") %>% dbGetQuery(pool,.)

# Process each file -------------------------------------------------------





for(file in files){
    # warning if already in files table
    # read file
    # md5
    # md5 changed if it was there before --> warning --> quit
    
    for(cp in std_cp){
        for(stat in stats){
            #if stat present warning and next
            
            # if this stat do this
            # calc stat
            # update db with stat
            
            # if this stat do this instead
            # calc stat
            # update db with stat
            
        } 
    }
}



