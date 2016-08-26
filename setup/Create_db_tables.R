# Libraries ---------------------------------------------------------------
library(DBI)
library(RMySQL)
library(MetabolomiQCsR)


# Establish connection ----------------------------------------------------
con <- dbConnect(MySQL(),
                 user     = MetabolomiQCsR.env$db$user,
                 password = MetabolomiQCsR.env$db$password, 
                 host     = MetabolomiQCsR.env$db$host, 
                 dbname   = MetabolomiQCsR.env$db$db)


# Kill existing tables ----------------------------------------------------
dbRemoveTable(con, "std_stat_data")
dbRemoveTable(con, "new_files")
dbRemoveTable(con, "files")
dbRemoveTable(con, "std_compounds")
dbRemoveTable(con, "std_stat_types")


# files -------------------------------------------------------------------
res <- dbSendQuery(con, "
                            CREATE TABLE new_files (
                            path TEXT(256) NOT NULL
                            )
                        "
                    )

dbClearResult(res)


res <- dbSendQuery(con, "
                            CREATE TABLE files (
                            path TEXT(256) NOT NULL,
                            file_md5 CHAR(32) PRIMARY KEY
                            )
                        "
                    )

dbClearResult(res)

# std_stat_types ----------------------------------------------------------
res <- dbSendQuery(con, "
                            CREATE TABLE std_stat_types (
                            stat_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
                            stat_type VARCHAR(20) NOT NULL,
                            stat_name VARCHAR(20) NOT NULL
                            )
                        "
                    )

dbClearResult(res)

# std_compounds -----------------------------------------------------------
res <- dbSendQuery(con, "
                            CREATE TABLE std_compounds (
                            cmp_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
                            cmp_name VARCHAR(20) NOT NULL,
                            cmp_mz FLOAT NOT NULL,
                            cmp_rt1 FLOAT NOT NULL,
                            cmp_rt2 FLOAT
                            )
                        "
                    )

dbClearResult(res)

# std_stat_data -----------------------------------------------------------
# reason the PRIMARY KEY is set this way: 
# http://weblogs.sqlteam.com/jeffs/archive/2007/08/23/composite_primary_keys.aspx

res <- dbSendQuery(con, "
                            CREATE TABLE std_stat_data (
                            file_md5 CHAR(32) NOT NULL, 
                            stat_id int NOT NULL,
                            cmp_id int NOT NULL,
                            FOREIGN KEY(file_md5) REFERENCES files(file_md5),
                            FOREIGN KEY(stat_id)  REFERENCES std_stat_types(stat_id),
                            FOREIGN KEY(cmp_id)   REFERENCES std_compounds(cmp_id),
                            value FLOAT NULL,
                            PRIMARY KEY(file_md5, stat_id, cmp_id)
                            )
                        "
                    )

dbClearResult(res)


# Close connection --------------------------------------------------------
dbDisconnect(con)
rm(res,con)
