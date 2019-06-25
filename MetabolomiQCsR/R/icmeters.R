#' Convert raw data into a tibble of xcmsRaw objects.
#'
#' @param user ICMeter username
#' @param pass ICMeter password
#'
#' @return A character vector containing the ICMeter token
#' 
#' @export
#'
#'@importFrom httr POST
#' 

ic_token <- function(user, pass){

token <- POST(url="https://app.ic-meter.com/icm/oauth/token",
     body = list(client_id = 'trusted-client',
            grant_type = 'password',
            scope = 'read',
            username = user,
            password = pass
     ),
     encode="form"
    )

token <- content(token)$access_token

return(token)
}



#' Convert raw data into a tibble of xcmsRaw objects.
#'
#' @param token A character vector containing the ICMeter token
#'
#' @return data.frame containing information about each box registered on the token account
#' 
#' @export
#'
#'@importFrom httr GET content
#'@importFrom dplyr mutate_at vars as.tbl
#' 

ic_boxes <- function(token){
    
    # make check happy
    fromDate <- lastMeasurementDate <- . <- NULL

    boxes <- GET(paste0("https://app.ic-meter.com/icm/api/boxlocations/1.0/list?access_token=",token))
    boxes <- content(boxes)
    boxes <- do.call(rbind.data.frame, c(boxes, stringsAsFactors = FALSE)) %>% as.tbl
    
    boxes %<>% mutate_at(vars(fromDate,lastMeasurementDate), ~as.POSIXct(strptime(.,"%Y-%m-%dT%H:%M:%SZ", tz="UTC")))
    
    return (boxes)
}



#' Convert raw data into a tibble of xcmsRaw objects.
#'
#' @param token A character vector containing the ICMeter token
#' @param boxQR A character vector containing QR code for the box you want to query
#' @param fromDate The starting date to draw data from
#' @param toDate The ending date to draw data to. A maximum of one month can be draw at a time.
#'
#' @return data.frame holding all the data drawn
#' 
#' @export
#'
#'@importFrom httr GET content
#'@importFrom dplyr mutate_at vars as.tbl mutate
#' 

ic_measurements <- function(token,  boxQR, fromDate, toDate){
    
    # make check happy
    Time <- . <- NULL
    
    
    # time formats
    fromDate <- format(fromDate, "%Y-%m-%dT%H:%M:%SZ")
    toDate <- format(toDate, "%Y-%m-%dT%H:%M:%SZ")
    
    
    # Indoor
    test_dat <- GET(paste0("https://app.ic-meter.com/icm/api/measurements/1.2/days/range/",boxQR,"?fromDate=",fromDate,"&toDate=",toDate,"&access_token=",token))
    
    test_dat <- content(test_dat)
    
    data <- lapply(test_dat$rows, function(x) unlist(x[[1]])) %>% 
            {do.call(rbind.data.frame, c(., stringsAsFactors = FALSE))} %>% 
            as.tbl
    
    
    names <- sapply(test_dat$cols, function(x) x$label)
    
    
    if(ncol(data)==0){
        data <- data.frame(a= character(0), b= character(0), c = character(0), d = character(0), stringsAsFactors = FALSE) %>% as.tbl
    }
    
    colnames(data) <- names
    
    data %<>% 
                mutate_at(vars(-Time), as.numeric) %>%
                mutate_at(vars(Time), ~as.POSIXct(strptime(.,"%Y-%m-%dT%H:%M:%SZ", tz="UTC")))
    
    data %<>% mutate(boxQR = boxQR)
    
    return(data)
}
