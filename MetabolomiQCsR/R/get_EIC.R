#' Calculate EIC from a raw matrix
#' 
#' Calculate EIC from a raw matrix of all observations (scan/mz/intensity combinations).
#'
#'
#' @param tbl A \code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{scan:} scan number
#'   \item \strong{scan_rt:} Retention time of scan
#'   \item \strong{intensity:} The intensity of the observation
#'   \item \strong{mz:} the mz of the observation
#' }
#' @param lower Lower boundary of EIC slice
#' @param upper Upper boundary of EIC slice
#' @param BPI Logical selecting to calculate TIC (FALSE) or BPI.
#'
#' @return tbl A \code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{scan:} scan number
#'   \item \strong{scan_rt:} Retention time of scan
#'   \item \strong{intensity:} The summed intensity for each scan in the given m/z interval
#' } 
#'
#' @keywords internal
#' @export
#'
#' @importFrom massageR is_between_1range
#' @importFrom dplyr mutate filter group_by summarise %>%
#' @importFrom magrittr %<>%
#' 
#' 

EIC_calc <- function(tbl, lower, upper, BPI = FALSE){
 
    keep <- mz <- scan_rt <- intensity <- NULL  # make build check happy
    
    
    tbl %<>% mutate(keep = is_between_1range(mz,lower,upper)) %>% 
            filter(keep) %>% 
            group_by(scan, scan_rt)
    
    if(BPI){
        tbl %<>% summarise(intensity = max(intensity))
    }else{
        tbl %<>% summarise(intensity = sum(intensity))
    }
            
    return(tbl)
}



#' Calculate EICs from a raw matrix using XCMS C function
#' 
#' Calculate EICs from a raw matrix of all observations (scan/mz/intensity combinations).
#' Can calculate for several ranges at a time
#'
#'
#' @param xraw_values A data.frame/\code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{scan:} scan number
#'   \item \strong{scan_rt:} Retention time of scan
#'   \item \strong{intensity:} The intensity of the observation
#'   \item \strong{mz:} the m/z of the observation
#' }
#' @param range_tbl data.frame/\code{\link{tibble}} with columns for the lower and upper ("mz_lower","mz_upper") m/z boundaries of EIC slice(s).
#'
#' @return tbl A \code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{scan:} scan number
#'   \item \strong{scan_rt:} Retention time of scan
#'   \item \strong{intensity:} The summed intensity for each scan in the given m/z interval
#' } 
#'
#' @keywords internal
#' @export
#'
#' @importFrom dplyr select distinct %>% bind_rows left_join group_nest
#' @importFrom magrittr %<>% extract2
#' @importFrom tibble tibble
#' @importFrom tidyr nest
#' 
#' 

getEIC_C_wrap <- function(xraw_values, range_tbl) {

    scan_rt <- range_id <- NULL  # make build check happy
    
    mz        <- xraw_values %>% extract2("mz")
    int       <- xraw_values %>% extract2("intensity")
    scanindex <- which(!duplicated(xraw_values$scan))-1 %>% as.integer
    
    N <- xraw_values %>% extract2("scan") %>% unique %>% length %>% as.integer

    scan_times <- xraw_values %>% select(scan,scan_rt) %>% distinct
    
    out <- list()
    
    for(i in 1:nrow(range_tbl)){
        out[[i]] <- .Call(  "getEIC",
                              mz,
                              int,
                              scanindex,
                              as.double(c(range_tbl$mz_lower[i],range_tbl$mz_upper[i])),
                              c(1L,N),
                              N,
                              PACKAGE ='xcms' 
                            )
        
        out[[i]] <- do.call(tibble,out[[i]])
    }
    
    
    out <-    bind_rows(out,.id = "range_id") %>% # we flatten everything to be able to match the RT to the scan fast
              left_join(scan_times, by="scan") %>%
              group_nest(across(c(range_id))) %>% # then we need to split things again
              extract2("data")

    return(out)
}
 


#' Get EICs from xcmsRaw object
#' 
#' Takes an \code{\link{xcmsRaw}} object and extracts EICs.
#' Can do multiple ranges and exclude certain masses unlike \code{\link{getEIC}}.
#' Can be used to extract the TIC too.
#'
#' @param xraw \code{\link{xcmsRaw}} object to get EIC(s)/TIC from.
#' @param range_tbl data.frame/\code{\link{tibble}} with columns for the lower and upper m/z boundaries of EIC slice(s).
#' @param exclude_mz Masses to exclude from the EIC. Most useful to remove contaminants from TICs.
#' @param exclude_ppm ppm tolerance of exclude_mz
#' @param range_tbl_cols Which columns in range_tbl holds the lower and upper range. defaults to c("mz_lower","mz_upper").
#' @param BPI Logical selecting to calculate TIC (FALSE) or BPI.
#' @param min_int the minimum intensity mass peak to include
#'
#' @return tbl A \code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{scan:} scan number
#'   \item \strong{scan_rt:} Retention time of scan
#'   \item \strong{intensity:} The summed intensity for each scan in the given m/z interval
#' } 
#' 
#' @export
#'
#' @importFrom massageR is_between
#' @importFrom tidyr fill
#' @importFrom dplyr rename bind_cols filter select as_tibble
#' @importFrom tibble tibble
#' @importFrom purrr map pmap
#' @importFrom magrittr extract2 %<>%
#' 

get_EICs <- function(xraw, range_tbl, exclude_mz = NULL, exclude_ppm = 30, range_tbl_cols = c("mz_lower","mz_upper"), BPI = FALSE, min_int = 0){
    
    # make build check happy
    . <- mz <- exclude <- mz_lower <- mz_upper <- EIC <- intensity <- NULL
    
    
    # get the right columns from range_tbl_cols
    range_tbl %<>% rename(mz_lower = range_tbl_cols[1],mz_upper = range_tbl_cols[2])

    
    # get raw values
    xraw_values <- tibble(intensity = xraw@env$intensity, mz = xraw@env$mz, scan = as.integer(NA))
    
    
    # Figure which scans each belongs to
    xraw_values$scan[xraw@scanindex+1] <- 1:length(xraw@scanindex)
    xraw_values %<>% fill(scan)
    
    
    # Get RTs for each scan
    xraw_values %<>% mutate(scan_rt = xraw@scantime[scan]/60)
    
    
    # If we need to exclude something remove it from the raw data
    if(!is.null(exclude_mz)){
        # Get ranges for mz's to exclude
        exclude_mz %>% 
                        tibble(mz=.) %>% 
                        mutate(mz_lower = mz-((exclude_ppm)/1E6)*mz, 
                               mz_upper = mz+((exclude_ppm)/1E6)*mz
                              ) ->
        exclude_mz_ranges
        
        
        # Figure which mz's to remove and remove
        xraw_values %<>% 
                            {is_between(.$mz,exclude_mz_ranges$mz_lower,exclude_mz_ranges$mz_upper)} %>% 
                            apply(1,any) %>% 
                            {bind_cols(xraw_values, tibble(exclude = .))} %>% 
                            filter(!exclude) %>% select(-exclude)
    }
    
    
    # Cut of everthing below the minimum intensity
    xraw_values %<>% filter(intensity>min_int)

    
    if(!BPI){ # if we don't need BPI we can use the fast C function
        range_tbl %<>% getEIC_C_wrap(xraw_values,.) %>% tibble(EIC = .) %>% bind_cols(range_tbl,.)
    }else{
    # Get EIC for each interval
    range_tbl %<>%      mutate(EIC   = pmap(list(mz_lower,mz_upper,BPI), function(lower,upper, BPI) EIC_calc(xraw_values, lower, upper, BPI = BPI)   )  ) %>% # get the EICs
                        mutate(EIC   = map(EIC,  ~ do.call(cbind.data.frame,.) %>% as_tibble  ))     # EICs are lists. make nice data.frame
    }              
    
    return(range_tbl %>% extract2("EIC"))
}

