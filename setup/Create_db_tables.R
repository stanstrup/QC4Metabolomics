# Libraries ---------------------------------------------------------------
library(DBI)
library(RMySQL)
library(MetabolomiQCsR)
library(pool) # devtools::install_github("rstudio/pool")


# Establish connection ----------------------------------------------------
pool <- dbPool(
                  drv = MySQL(),
                  dbname = MetabolomiQCsR.env$db$db,
                  host = MetabolomiQCsR.env$db$host,
                  username = MetabolomiQCsR.env$db$user,
                  password = MetabolomiQCsR.env$db$password,
                  idleTimeout = 0.5*1000*60*60 # ½ hour
)


# Kill existing tables ----------------------------------------------------
if(FALSE){
    dbRemoveTable(pool, "std_stat_data")
    dbRemoveTable(pool, "new_files")
    dbRemoveTable(pool, "files")
    dbRemoveTable(pool, "std_compounds")
    dbRemoveTable(pool, "std_stat_types")
}


# files -------------------------------------------------------------------
con <- poolCheckout(pool)

res <- dbSendQuery(con, "
                            CREATE TABLE new_files (
                            path TEXT(256) NOT NULL
                            )
                        "
                    )



res <- dbSendQuery(con, "
                            CREATE TABLE files (
                            path TEXT(256) NOT NULL,
                            file_md5 CHAR(32) PRIMARY KEY
                            )
                        "
                    )

poolReturn(con)


# std_stat_types ----------------------------------------------------------
con <- poolCheckout(pool)

res <- dbSendQuery(con, "
                            CREATE TABLE std_stat_types (
                            stat_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
                            stat_type VARCHAR(20) NOT NULL,
                            stat_name VARCHAR(20) NOT NULL
                            )
                        "
                    )

poolReturn(con)


# std_compounds -----------------------------------------------------------
con <- poolCheckout(pool)

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

poolReturn(con)


# std_stat_data -----------------------------------------------------------
# reason the PRIMARY KEY is set this way: 
# http://weblogs.sqlteam.com/jeffs/archive/2007/08/23/composite_primary_keys.aspx

con <- poolCheckout(pool)

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

poolReturn(con)


# Close connection --------------------------------------------------------
poolClose(pool)
rm(res,pool)
