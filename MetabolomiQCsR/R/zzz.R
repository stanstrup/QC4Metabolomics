
#' When the package is loaded read an ini file to get config parameters
#'
#' @return Hidden environment MetabolomiQCsR.env containing settings from MetabolomiQCs.conf
#' @importFrom ini read.ini
#' @importFrom stringr str_split
#' @noRd
#'

.onAttach <- function(libname = find.package("MetabolomiQCsR"), pkgname = "MetabolomiQCsR") {

    #### read ini file
    
    # search locations
    ini_file <- c("./MetabolomiQCs.conf", # if file in working dir use that
                  "../MetabolomiQCs.conf", # one folder back
                  "~/MetabolomiQCs.conf", # if file in home folder
                  system.file("extdata", "MetabolomiQCs.conf", package = "MetabolomiQCsR") # If no file found use the one from the package
    )
    
    
    # check if we can find any config file at all
    if(all(!file.exists(ini_file))) stop("No MetabolomiQCs.conf found.\n
                                         This should not happen since the packages comes with a default configuration file.")
    
    
    # Get the first of the files in the above list
    ini_file <- ini_file[file.exists(ini_file)][1]
    
    # read the ini file
    packageStartupMessage(paste0("Using MetabolomiQCsR configuration file in: ",normalizePath(ini_file)))
    ini <- read.ini(normalizePath(ini_file))
    
    
    
    #### Read ini file data into environment
    MetabolomiQCsR.env                                         <- NULL
    MetabolomiQCsR.env                                         <<- new.env()
    
	MetabolomiQCsR.env$general$settings_file                   <<- normalizePath(ini_file)
    MetabolomiQCsR.env$general$base                            <<- ini$general$base %>% as.character
    
    MetabolomiQCsR.env$TIC$TIC_exclude                         <<- ini$visualization$TIC_exclude %>% str_split(",") %>% unlist %>% as.numeric
    MetabolomiQCsR.env$TIC$TIC_exclude_ppm                     <<- ini$visualization$TIC_exclude_ppm %>% as.numeric
    
    MetabolomiQCsR.env$db$db                                   <<- ini$db$db %>% as.character
    MetabolomiQCsR.env$db$user                                 <<- ini$db$user %>% as.character
    MetabolomiQCsR.env$db$password                             <<- ini$db$password %>% as.character
    MetabolomiQCsR.env$db$host                                 <<- ini$db$host %>% as.character

    
}



# Remove config environment on unload
.onDetach <- function(libpath = find.package("MetabolomiQCsR")) {
    rm(MetabolomiQCsR.env,envir = globalenv())
}
