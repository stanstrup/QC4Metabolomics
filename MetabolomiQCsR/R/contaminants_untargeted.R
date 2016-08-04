#' Find EICs that behave like contaminants
#'
#' This function looks in raw LC-MS data for "features"/EICs that behave like contaminants.
#' Behaving like contaminants in this case means that a certain m/z values is 
#' present in more than \code{min_time} above intensity \code{min_int}.
#'
#' @param raw \code{\link{xcmsRaw}} object to profile
#' @param bin_ppm Tolerance (ppm) for initial binning of m/z values
#' @param interval_ppm Tolerance for creating final EICs after merging similar bins
#' @param min_time Minimum time (minutes) an EIC should be above \code{min_int} to be considered a contaminant.
#' @param merge_corr Minimum correlation between EICs to be merged.
#' @param merge_ppm Maximum difference (ppm) between EICs to be merged.
#' @param min_int Minimum intensity that the EIC needs to be above for a a minimum of \code{min_time}.
#'
#' @return A \code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{mz:} m/z of the proposed contaminant
#'   \item \strong{EIC:} EIC of the m/z.
#' }
#' 
#' @importFrom massageR which.median longest_piece_above loc_mat_2_group_idx seq_rel
#' @importFrom tibble data_frame
#' @importFrom dplyr %>% filter arrange mutate group_by ungroup summarise bind_cols select n
#' @importFrom purrr map_lgl map
#' @importFrom WGCNA cor allowWGCNAThreads
#' @importFrom magrittr extract2 %<>% 
#' @importFrom stats median
#' 
#' @export
#'

EIC_contaminants <- function(raw, bin_ppm = 30, interval_ppm = 30, min_time = 5, merge_corr = 0.9, merge_ppm = 30, min_int = 5000) {
    
    # Make build check happy
    seq1_bin <- seq2_bin <- seq2_n <- seq1_n <- mz_lower <- mz_upper <- noise <- EIC <- . <- intensity <- NULL
    
    # find now make scans per minute we have
    scan_per_min <- 60/as.numeric(names(which.max(table(diff(raw@scantime)))))
    
    # put raw data in a matrix
    raw_mat <- data_frame(mz = raw@env$mz, intensity = raw@env$intensity)    
    
    
    # Generate mz slices. They are ppm so size will change over the range
    seq1 <- seq_rel(from = min(raw_mat$mz),        to = max(raw_mat$mz), by = bin_ppm/1E6 )
    
    lower <- seq1[-length(seq1)]
    upper <- seq1[2:length(seq1)]
    seq2 <- lower+(upper-lower)/2 # midpoints in seq1
    
    
    # Cut mz values in slices and filter slices with too few values
    raw_mat_seq <- raw_mat %>%  filter(intensity>min_int) %>% 
                                arrange(mz) %>% 
                                mutate(seq1_bin = .bincode(mz,seq1)) %>% 
                                mutate(seq2_bin = .bincode(mz,seq2)) %>% 
                                group_by(seq1_bin) %>% mutate(seq1_n = n()) %>% 
                                group_by(seq2_bin) %>% mutate(seq2_n = n()) %>% 
                                ungroup %>% 
                                filter(seq1_n > scan_per_min*min_time | seq2_n > scan_per_min*min_time )
    
    
    # Get actual median mz values in each bin
    raw_mat_seq_sum1 <- raw_mat_seq %>% group_by(seq1_bin) %>% summarise(median_mz = median(mz))
    
    raw_mat_seq_sum2 <- raw_mat_seq %>% group_by(seq2_bin) %>% summarise(median_mz = median(mz))
    
    median_mzs <- c(raw_mat_seq_sum1$median_mz, raw_mat_seq_sum2$median_mz) %>% unique
    
    
    # Make intervals around the actual median mz values
    EIC_intervals <- data_frame(mz=median_mzs, 
                                mz_lower = mz-(interval_ppm/1E6)*mz, 
                                mz_upper = mz+(interval_ppm/1E6)*mz
                                ) 
    
    # Get all EICs
    EICs <- get_EICs(raw, EIC_intervals)
    
    data <- bind_cols(EIC_intervals, EIC = data_frame(EIC = EICs))
    
    
    
    # check if the EICs behave like contaminants
    data %<>%    mutate(noise   = map_lgl(EIC,  ~ longest_piece_above(X = .x$intensity, Y = min_int) < min_time/median(diff(.x$scan_rt))
                                          )
                        )
        
        
    # keep only noise-like things
    data %<>% filter(!noise)
    
    
    
    
    # Calculate EIC correlation and mz closeness
    allowWGCNAThreads() # this is for using WGCNA::cor

        corr <- map(data$EIC, ~ .x$intensity) %>% do.call(cbind,.) %>% cor
        diff <- data %>% extract2("mz") %>% outer(.,.,FUN = function(a,b) abs(  (a-b)/mean(c(a,b))  ) * 1E6 )
    
        
    # group similar EICs
        is_same <- (corr > merge_corr) & (diff < merge_ppm)
        
        same_idx <- loc_mat_2_group_idx(is_same)
        
        
    # Find the median mz of each EIC group
        mz <- data %>% extract2("mz")
        
        mz_median <- sapply(same_idx, function(y){
                                                    idx_median <- which.median(mz[y]) # we cannot take the median since it takes the mean when there are an even number of values
                                                    num_label_median <- mz[y][idx_median]
                                                    return(num_label_median)
                                                   }
                            )
        
        
        # Get the EICs with the median mz values of the similar groups
        data %<>% filter(mz %in% mz_median) %>% select(-mz_lower, -mz_upper, -noise)
        
    
        return(data)
}



