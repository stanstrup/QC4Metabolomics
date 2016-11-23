# Connect to db -----------------------------------------------------------
pool <- dbPool_MetabolomiQCs(5)



# Make query --------------------------------------------------------------
con <- poolCheckout(pool)
dbBegin(con)


    dbSendQuery(con, 
                "DELETE FROM log WHERE time < DATE_SUB(NOW(), INTERVAL 1 MONTH);"
                )
    
    suc <- dbCommit(con)


poolReturn(con)

if(isTRUE(suc)){
    write_to_log("Log entries older than 1 month deleted successfully.", cat = "info", pool = pool)
}else{
    write_to_log("Log cleanup failed.", cat = "error", pool = pool)
}


# Close connection --------------------------------------------------------
poolClose(pool)
rm(pool, con)
