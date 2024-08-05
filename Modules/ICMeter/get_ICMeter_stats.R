log_source <- "ICMeter"

# Getting all data sequentially -------------------------------------------
token <- ic_token(Sys.getenv("QC4METABOLOMICS_module_ICMeter_user"),Sys.getenv("QC4METABOLOMICS_module_ICMeter_password"))
boxes <- ic_boxes(token)


offset <- days(0)
pool   <- dbPool_MetabolomiQCs(30)


for(device in boxes$name){
    while(TRUE){
        # get the times
        to_db <- paste0("SELECT MAX(time) AS time FROM ic_data WHERE device='",device,"'") %>%
                 dbGetQuery(pool,.) %>% 
                 extract2("time")
        
        
        boxQR_sel <- boxes %>% filter(name==device)     %>% extract2("boxQR")
        from_box <-  boxes %>% filter(boxQR==boxQR_sel) %>% extract2("fromDate")
        to_box   <-  boxes %>% filter(boxQR==boxQR_sel) %>% extract2("lastMeasurementDate") 
        
       
        # if we have data from within the last 5 minutes we stop
        if(to_box + offset + minutes(10) > Sys.time()){
            write_to_log(paste0("Device: ",device," No more data from last recorded time point that was ", to_box), cat = "info", source = log_source, pool = pool)
            offset <- days(0)
            break
        }
        
        # If no data in db we want to pull from the first datapoint we have in the remote db
        # else we pull from the last point we have
        
        if(is.na(to_db)){
            from_select <- from_box
        }else{
            from_select <- to_db %>% {as.POSIXct(strptime(.,"%Y-%m-%d %H:%M:%S", tz="UTC"))}
        }
        
        # get from the selected time and 30 days ahead
        data <- ic_measurements(token = token, 
                                boxQR = boxQR_sel,
                                fromDate = from_select+seconds(1)+offset,
                                toDate = from_select+days(30)+offset
        )
        
        
        
        if(nrow(data)==0){
            write_to_log(paste0("Device: ",device,". No data found in the period from ",from_select+seconds(1)+offset," to ",from_select+days(30)+offset), cat = "info", source = log_source, pool = pool)
            offset <- offset+days(25)
            next
        }else{
            write_to_log(paste0("Device: ",device,". ",nrow(data), " datapoints added from the period ",from_select+seconds(1)+offset," to ",from_select+days(30)+offset), cat = "info", source = log_source, pool = pool)
            offset <- days(0)
        }
        
        data %<>% left_join(boxes %>% select(boxQR, name), by = "boxQR")
        data_long <- data %>% gather(metric, value, -Time,-boxQR,-name) %>% rename(device=name, time = Time) %>% select(-boxQR)
        
        data_long %<>% mutate(time = format(time, "%Y-%m-%d %H:%M:%S"))
        
        # write to the db
        con <- poolCheckout(pool)
        
        dbBegin(con)
        
        sql_query <- data_long %>% sqlAppendTable(con, "ic_data", .) 
        
        sql_query@.Data <- paste0(sql_query@.Data, "\n  ","ON DUPLICATE KEY UPDATE value = values(value)") 
        
        res <- dbSendQuery(con,sql_query)
        
        res <- dbCommit(con)
        
        poolReturn(con)
        
        # rm
        rm(boxQR_sel, from_box, to_box, from_select, data_long, data, res, con)
          
    }
}


# close connections
poolClose(pool)
