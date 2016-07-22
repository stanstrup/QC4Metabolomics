globalVariables("MetabolomiQCsR.env")


#' Get list of known contaminants
#'
#' @param polarity The polarity to get contaminants for. Can be "positive", "negative" or "unknown".
#' If "unknown" the list specified in the MetabolomiQCsR.conf is used. 
#' MetabolomiQCsR.conf can be in the working folder or the home folder.
#' If those are not found the package default is used (unknown will used the positive mode list).
#' @param type If using local or remote. 
#' Only "URL" implemented which downloads a list from https://github.com/stanstrup/common_mz
#'
#' @return tbl A \code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{Monoisotopic ion mass (singly charged):} m/z of the contaminant
#'   \item \strong{Ion type:} Notation for adduct/fragment type
#'   \item \strong{Formula for M or subunit or sequence:} Molecular formula
#'   \item \strong{Compound ID or species:} Name of the compound
#'   \item \strong{Possible origin and other comments:} Suggestion for the origin of the contaminant
#'   \item \strong{References:} Reference for the contaminant
#' }
#' 
#' @references https://github.com/stanstrup/common_mz
#' 
#' @export
#'
#' @importFrom tibble data_frame
#' @importFrom dplyr filter mutate as.tbl left_join %>%
#' @importFrom purrr map_chr map
#' @importFrom readr read_tsv
#' @importFrom magrittr extract2
#' @importFrom RCurl getURL
#' @importFrom utils globalVariables suppressForeignCheck
#' 

get_cont_list <- function(polarity = c("positive", "negative", "unknown"), type = "URL") {

    # make build check happy
    . <- loc <- NULL

    polarity_un <- unique(polarity)
    
    if(type=="URL"){
        cont_list <- MetabolomiQCsR.env$target_cont$cont_list$loc %>% 
                     {data_frame(polarity = names(.),loc = as.character(.))} %>% 
                     filter(polarity %in% polarity_un) %>% 
                     mutate(cont_list = map_chr(loc, getURL)) %>% 
                     mutate(cont_list = map(cont_list, read_tsv))
    }else{return(NULL)}
    
    out <- polarity %>% 
                         {data_frame(polarity=.)} %>% as.tbl %>% 
                          left_join(cont_list, by="polarity") %>% 
                          extract2("cont_list")
    
    return(out)
}
