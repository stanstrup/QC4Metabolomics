#' Convert a list of peaks (rt / m/z pairs) to a Region of Interest (ROI) list for use with \code{\link{findPeaks}}
#'
#' @param tbl \code{\link{tibble}} containing the columns "rt" and "mz". rt needs to be in seconds.
#' @param raw \code{\link{xcmsRaw}} object to create ROI for. It needs to be a specific \code{\link{xcmsRaw}} to match retention times to scan nubmers.
#' @param ppm ppm tolerance for the generated ROI.
#' @param rt_tol Retention time tolerance (in sec!) for the generated ROI.
#'
#' @return List containing the ROIs. Each list contains mz, mzmin, mzmax, scmin, scmax, length (set to -1, not used by centWave) and intensity (set to -1, not used by centWave) columns.
#' @export
#' 
#' @importFrom dplyr %>% rowwise transmute ungroup mutate
#' @importFrom purrr by_row map
#' @importFrom massageR attr_rem
#' @importFrom magrittr extract2
#' 

tbl2ROI <- function(tbl, raw, ppm, rt_tol) {

    rt <- mz <- .out <- NULL
    
    tbl %>% 
             rowwise %>% 
             transmute(mz        = mz, # not used!
                       mzmin     = mz - ppm * mz * 1E-6, 
                       mzmax     = mz + ppm * mz * 1E-6,
                       scmin     = which.min(abs((rt-rt_tol)-raw@scantime)),
                       scmax     = which.min(abs((rt+rt_tol)-raw@scantime)),
                       length    = -1, # not used!
                       intensity = -1  # not used!
                       ) %>%
             ungroup %>% 
        
             by_row(as.list) %>% 
             mutate( .out = map(.out, ~ attr_rem(.x,"indices"))) %>% # we get some indices attribute. Dunno why. But lets remove it.
             extract2(".out") ->
    out
    
    return(out)
}





#' Match list of standards to peak table
#'
#' This function will match a table of standard compounds and a peak table by m/z and retention time.
#' If there is more than one possible hit the highest intensity peak will be chosen.
#'
#' @param stds \code{\link{tibble}} of standards to match to a peak table
#' @param peakTable \code{\link{tibble}} containing peak table supplied by \code{\link{findPeaks}} (but converted to \code{\link{tibble}}/\code{\link{data.frame}}).
#' @param rt_tol Retention time tolerance for matching peaks. Pay attention to the unit of your tables.
#' rt_tol should match and stds and peakTable should use same units (i.e. minutes of seconds).
#' @param mz_ppm ppm for matching peaks.
#' @param rt_col Character string giving the column containing the retention times. Must be same in standards and peak table.
#' @param mz_col Character string giving the column containing the m/z values. Must be same in standards and peak table. 
#' @param int_col Character string giving the column containing the intensities in the peak table. 
#'
#' @return A vector having the length equivalent to the number of rows in stds giving the indices of the hits in peakTable.
#' 
#' @export
#'
#' @importFrom magrittr extract2
#' @importFrom dplyr %>% slice
#'

closest_match <- function(stds, peakTable, rt_tol = 0.25, mz_ppm = 30, rt_col = "rt", mz_col = "mz", int_col = "into"){
    
    indices <- rep_len(as.numeric(NA), nrow(stds))
    
    peakTable_mz <- peakTable %>% extract2(mz_col)
    peakTable_rt <- peakTable %>% extract2(rt_col)
        
    for(i in 1:nrow(stds)){
        
        stds_mz <- stds %>% slice(i) %>% extract2(mz_col)
        stds_rt <- stds %>% slice(i) %>% extract2(rt_col)
        
        
        idx <-  abs(stds_rt-peakTable_rt) < rt_tol & 
               (abs(stds_mz-peakTable_mz)/stds_mz)*1E6 <  mz_ppm
        
        # no match is found
        if(sum(idx)==0){ next } # we filled the vector with NA so we don't need to do anyting
        
        # 1 match is found
        if(sum(idx)==1){
            indices[i] <- which(idx) 
            next
            }
        
        # More than one match is found. We take the highest intensity peak then
        if(sum(idx)>1){
            idx2       <- peakTable %>% slice(which(idx)) %>% extract2(int_col) %>% which.max
            indices[i] <- which(idx)[idx2]
            next
            }
            
    }
    
    return(indices)
}





#' Calculate Tailing Factor and Asymmetry Factor
#'
#' @param EIC EIC containing the peak to calculate for. 
#' \code{\link{tibble}} as produced with \code{\link{get_EICs}}.
#' @param rt Retention time of the center of the peak (Numeric)
#' @param factor to calculate. Character string either "TF" (Tailing Factor) or "ASF" (Asymmetry Factor).
#'
#' @references http://www.chromforum.org/viewtopic.php?t=20079
#'
#' @return Numeric
#' @export
#'
#' @importFrom dplyr %>% filter arrange desc mutate slice
#' @importFrom stats approx
#'

#'

peak_factor <- function(EIC, rt, factor="TF"){

    intensity <- per_max <- scan_rt <- NULL
    
    if(is.na(rt)) return(NA)
    
    # C = midpoint = highest scan
    C <- rt # EIC is in minutes so we change here
    
    C_scan <- EIC$scan[    which.min(abs(EIC$scan_rt-C))   ]
    
    C <- EIC %>% filter(scan==C_scan) %>% extract2("scan_rt")
    
    
    # Get the lower RT side of the peak
    A_side <-   EIC %>% 
                filter(scan <= C_scan) %>% 
                arrange(desc(scan)) %>% 
                mutate(per_max = intensity/intensity[1])
    
    # Get the upper RT side of the peak
    B_side <-   EIC %>% 
                filter(scan >= C_scan) %>% 
                arrange(scan) %>% 
                mutate(per_max = intensity/intensity[1])
    
    
    # which factor are we doing?
    cut_off <- switch(factor, TF=0.05, ASF=0.1)
    
    
    
    # Get A
    A_scans <- A_side %>% with(match(-1,sign(per_max-cut_off)))
    
    A       <- A_side %>% 
               slice((A_scans-1):A_scans) %>% 
               with(approx(per_max,scan_rt,xout=cut_off)$y)
    
    
    # Get B
    B_scans <- B_side %>% with(match(-1,sign(per_max-cut_off)))
    
    B       <- B_side %>% 
               slice((B_scans-1):B_scans) %>% 
               with(approx(per_max,scan_rt,xout=cut_off)$y)
    
    
    
    if(factor=="TF") return(   (B-A)/(2*(C-A))   )
    
    if(factor=="ASF") return(   (B-C)/(C-A)   )
}
