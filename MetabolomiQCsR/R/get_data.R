#' Get table with QC4metabolomics settings
#'
#' @param modules character strong. Get settings only for selected modules.
#'
#' @return tbl A \code{\link{tibble}} containing the columns: 
#' \itemize{
#'   \item \strong{name:} name of the setting
#'   \item \strong{value:} value of the settin
#'   \item \strong{module:} which module the setting belongs to.
#' }
#' 
#' @export
#'
#' @importFrom tibble tibble
#' @importFrom dplyr filter mutate if_else select %>%
#'

get_QC4Metabolomics_settings <- function(modules=NULL) {
  

  
  
  
  module_tbl <- Sys.getenv() %>% 
                    {tibble(name = names(.), value = .)  } %>% 
                    filter(grepl("^QC4METABOLOMICS_.*$",name) | grepl("MYSQL_DATABASE|MYSQL_HOST|MYSQL_USER|MYSQL_PASSWORD|MYSQL_PORT",name)) %>%
                    mutate(module = gsub("^QC4METABOLOMICS_module_(.*?)_.*$","\\1",name)) %>%
                    mutate(is_module = grepl("QC4METABOLOMICS_module",name)) %>% 
                    mutate(module = if_else(is_module, module, NA)) %>% 
                    select(name, value, module)
  
  if(!is.null(modules)){
    module_tbl <-  module_tbl %>% filter(module %in% modules)
  }
  
  return(module_tbl)
  
}



#' Set QC4metabolomics settings form env file
#'
#' @param file character string with the filename of the env file
#'

#' 
#' @export
#'
#' @importFrom purrr map
#' @importFrom dplyr %>%
#'

set_QC4Metabolomics_settings_from_file <- function(file) {
  
  if (missing(file)) {
    stop("Please provide a filename for the env_file")
  }
  
  
  env_file <- readLines(file)
  
  grep("QC4METABOLOMICS_|MYSQL_DATABASE|MYSQL_HOST|MYSQL_USER|MYSQL_PASSWORD|MYSQL_PORT", env_file, value = TRUE) %>% 
    strsplit("=") %>% 
    map(~setNames(..1[2], ..1[1])) %>%
    unlist() %>% 
    as.list() %>% 
    do.call("Sys.setenv",.)
  
}












#' Get list of known contaminants
#'
#' @param polarity The polarity to get contaminants for. Can be "positive", "negative" or "unknown".
#' If "unknown" the list specified in the MetabolomiQCs.conf is used. 
#' MetabolomiQCs.conf can be in the working folder or the home folder.
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
#' @importFrom tibble tibble
#' @importFrom dplyr filter mutate as_tibble left_join %>% pull
#' @importFrom purrr map_chr map
#' @importFrom readr read_tsv
#' @importFrom magrittr extract2
#' @importFrom httr GET content
#' 

get_cont_list <- function(polarity = c("positive", "negative", "unknown"), type = "URL") {

    # make build check happy
    . <- loc <- NULL

    # get settings
    loc <- list()
    loc$positive      <- get_QC4Metabolomics_settings() %>% filter(module=="Contaminants") %>% filter(grepl("cont_list_loc_positive",name)) %>% pull(value)
    loc$unknown       <- get_QC4Metabolomics_settings() %>% filter(module=="Contaminants") %>% filter(grepl("cont_list_loc_unknown",name)) %>% pull(value)
    loc$negative      <- get_QC4Metabolomics_settings() %>% filter(module=="Contaminants") %>% filter(grepl("cont_list_loc_negative",name)) %>% pull(value)
    
    

    polarity_un <- unique(polarity)
    
    if(type=="URL"){
        cont_list <- loc %>% 
                     {tibble(polarity = names(.),loc = as.character(.))} %>% 
                     filter(polarity %in% polarity_un) %>% 
                     mutate(cont_list = map_chr(loc, ~content(GET(..1)))) %>% 
                     mutate(cont_list = map(cont_list, read_tsv))
    }else{return(NULL)}
    
    out <- polarity %>% 
                         {tibble(polarity=.)} %>% as_tibble %>% 
                          left_join(cont_list, by="polarity") %>% 
                          extract2("cont_list")
    
    return(out)
}

