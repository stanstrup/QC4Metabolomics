# Libraries ---------------------------------------------------------------
library(DBI)
library(RMySQL)
library(MetabolomiQCsR)
library(pool) # devtools::install_github("rstudio/pool")
library(magrittr)


# Establish connection ----------------------------------------------------
pool <- dbPool_MetabolomiQCs(5)


# Kill existing tables ----------------------------------------------------
if(TRUE){
    dbRemoveTable(pool, "std_stat_data")
    dbRemoveTable(pool, "new_files")
    dbRemoveTable(pool, "files")
    dbRemoveTable(pool, "std_compounds")
    dbRemoveTable(pool, "std_stat_types")
    dbRemoveTable(pool, "log")
}


# files -------------------------------------------------------------------
sql <- "
        CREATE TABLE new_files (
        path          TEXT(256)     NOT NULL
        )
       "


sql <- c(sql, "
                CREATE TABLE files (
                path TEXT(256) NOT NULL,
                file_md5 CHAR(32) PRIMARY KEY,
                project       VARCHAR(256)  NOT NULL,
                instrument    TEXT(256)     NOT NULL,
                mode          ENUM('pos', 'neg','unknown') NOT NULL,
                time_filename DATE          NOT NULL,
                batch_seq_nr  SMALLINT      NOT NULL,
                sample_id     TEXT(256)     NOT NULL,
                sample_ext_nr SMALLINT      NOT NULL,
                inst_run_nr   SMALLINT      NOT NULL,
                time_run      DATETIME      NOT NULL
                )
              "
             )


# std_stat_types ----------------------------------------------------------
sql <- c(sql, "
                CREATE TABLE std_stat_types (
                stat_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
                stat_name VARCHAR(20) NOT NULL
                )
               "
         )

sql <- c(sql, "
                INSERT INTO std_stat_types (stat_name)
                VALUES ('mz'),('mzmin'),('mzmax'),
                       ('rt'),('rtmin'),('rtmax'),
                       ('into'),('intb'),('maxo'),
                       ('sn'),('egauss'),('mu'),('sigma'),('h'),('f'),
                       ('mz_dev_ppm'),('rt_dev'),('FWHM'),('datapoints'),('TF'),('ASF');
               "
         )

# std_compounds -----------------------------------------------------------
sql <- c(sql, "
                CREATE TABLE std_compounds (
                cmp_id   int                NOT NULL AUTO_INCREMENT PRIMARY KEY,
                cmp_name TEXT               NOT NULL,
                mode     ENUM('pos', 'neg') NOT NULL,
                cmp_mz   DOUBLE             NOT NULL,
                cmp_rt1  DOUBLE             NOT NULL,
                cmp_rt2  DOUBLE,
                enabled  BOOL               NOT NULL,
                updated_at TIMESTAMP        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                KEY (updated_at)
                )
              "
         )


# std_stat_data -----------------------------------------------------------
# reason the PRIMARY KEY is set this way: 
# http://weblogs.sqlteam.com/jeffs/archive/2007/08/23/composite_primary_keys.aspx

sql <- c(sql, "
                CREATE TABLE std_stat_data (
                file_md5 CHAR(32) NOT NULL, 
                stat_id  int      NOT NULL,
                cmp_id   int      NOT NULL,
                found    BOOL     NOT NULL,
                FOREIGN KEY(file_md5) REFERENCES files(file_md5),
                FOREIGN KEY(stat_id)  REFERENCES std_stat_types(stat_id),
                FOREIGN KEY(cmp_id)   REFERENCES std_compounds(cmp_id),
                value DOUBLE NULL,
                PRIMARY KEY(file_md5, stat_id, cmp_id)
                )
               "
         )



# Log ---------------------------------------------------------------------
sql <- c(sql, "
                CREATE TABLE log (
                id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
                time          DATETIME      NOT NULL,
                msg           TEXT          NOT NULL,
                cat           ENUM('info', 'warning','error') NOT NULL,
                source        VARCHAR(256)  NOT NULL
                )
               "
         )


# Write to db -------------------------------------------------------------
suc <- vector(length=length(sql))

paste0(length(sql), " queries to make.\n") %>% 
    message()


con <- poolCheckout(pool)
dbBegin(con)

for(i in seq_along(sql)){
    dbSendQuery(con, sql[i])
    suc[i] <- dbCommit(con)
}

poolReturn(con)

ifelse(all(suc),"All queries were successful.\n",  paste0("Queries ",paste(which(!suc),collapse=", ")," failed.\n")   ) %>% 
    message

# Close connection --------------------------------------------------------
poolClose(pool)
rm(pool, con, suc, sql, i)
