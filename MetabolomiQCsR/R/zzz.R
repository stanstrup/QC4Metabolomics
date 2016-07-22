
#' When the package is loaded read an ini file to get config parameters
#'
#' @return Hidden environment MetabolomiQCsR.env containing settings from MetabolomiQCsR.conf
#' @importFrom ini read.ini
#' @importFrom stringr str_split
#' @noRd
#'

.onAttach <- function(libname = find.package("MetabolomiQCsR"), pkgname = "MetabolomiQCsR") {

    #### read ini file
    
    # search locations
    ini_file <- c("./MetabolomiQCsR.conf", # if file in working dir use that
                  "~/MetabolomiQCsR.conf", # if file in home folder
                  system.file("extdata", "MetabolomiQCsR.conf", package = "MetabolomiQCsR") # If no file found use the one from the package
    )
    
    
    # check if we can find any config file at all
    if(all(!file.exists(ini_file))) stop("No MetabolomiQCsR.conf found.\nThis should not happen since the packages comes with a default configuration file.")
    
    
    # Get the first of the files in the above list
    ini_file <- ini_file[file.exists(ini_file)][1]
    
    # read the ini file
    packageStartupMessage(paste0("Using MetabolomiQCsR configuration file in: ",normalizePath(ini_file)))
    ini <- read.ini(normalizePath(ini_file))
    
    
    
    #### Read ini file data into environment
    MetabolomiQCsR.env                                         <- NULL
    MetabolomiQCsR.env                                         <<- new.env()
    MetabolomiQCsR.env$target_cont$EIC_ppm                     <<- ini$target_cont$EIC_ppm                 %>% as.numeric
    MetabolomiQCsR.env$target_cont$cont_list$cont_list_type    <<- ini$target_cont$cont_list_type          %>% as.character
    MetabolomiQCsR.env$target_cont$cont_list$loc$positive      <<- ini$target_cont$cont_list_loc_positive  %>% as.character
    MetabolomiQCsR.env$target_cont$cont_list$loc$unknown       <<- ini$target_cont$cont_list_loc_unknown   %>% as.character
    MetabolomiQCsR.env$target_cont$cont_list$loc$negative      <<- ini$target_cont$cont_list_loc_negative  %>% as.character
    MetabolomiQCsR.env$TIC$TIC_exclude                         <<- ini$visualization$TIC_exclude %>% str_split(",") %>% unlist %>% as.numeric
    MetabolomiQCsR.env$TIC$TIC_exclude_ppm                     <<- ini$visualization$TIC_exclude_ppm %>% as.numeric
    rm(ini)
    
}



# Remove config environment on unload
.onDetach <- function(libpath = find.package("MetabolomiQCsR")) {
    rm(MetabolomiQCsR.env,envir = globalenv())
}
