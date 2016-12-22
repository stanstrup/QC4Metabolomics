
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
    if(all(!file.exists(ini_file))) stop("No MetabolomiQCs.conf found.\nThis should not happen since the packages comes with a default configuration file.")
    
    
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
    
    MetabolomiQCsR.env$db$db                                   <<- ini$db$db %>% as.character
    MetabolomiQCsR.env$db$user                                 <<- ini$db$user %>% as.character
    MetabolomiQCsR.env$db$password                             <<- ini$db$password %>% as.character
    MetabolomiQCsR.env$db$host                                 <<- ini$db$host %>% as.character
    
    MetabolomiQCsR.env$folders$base                            <<- ini$folders$base %>% as.character
    MetabolomiQCsR.env$folders$include_ext                     <<- ini$folders$include_ext %>% as.character
    MetabolomiQCsR.env$folders$include_path                    <<- ini$folders$include_path %>% as.character
    MetabolomiQCsR.env$folders$exclude_path                    <<- ini$folders$exclude_path %>% as.character
    
    MetabolomiQCsR.env$files$mask                              <<- ini$files$mask     %>% as.character
    MetabolomiQCsR.env$files$datemask                          <<- ini$files$datemask %>% as.character
    
    MetabolomiQCsR.env$files$mode_from_other_field             <<- ini$files$mode_from_other_field            %>% as.logical
    MetabolomiQCsR.env$files$mode_from_other_field_which       <<- ini$files$mode_from_other_field_which      %>% as.character
    MetabolomiQCsR.env$files$mode_from_other_field_pos_trigger <<- ini$files$mode_from_other_field_pos_trigger %>% as.character
    MetabolomiQCsR.env$files$mode_from_other_field_neg_trigger <<- ini$files$mode_from_other_field_neg_trigger %>% as.character
    
    MetabolomiQCsR.env$xcmsRaw$profparam                       <<- ini$xcmsRaw$profparam %>% as.numeric %>% {list(step=.)}

    MetabolomiQCsR.env$std_match$ppm                           <<- ini$std_match$ppm %>% as.numeric
    MetabolomiQCsR.env$std_match$rt_tol                        <<- ini$std_match$rt_tol %>% as.numeric
    
    MetabolomiQCsR.env$findPeaks$ROI_ppm                       <<- ini$findPeaks$ROI_ppm %>% as.numeric
    
    MetabolomiQCsR.env$findPeaks$method                        <<- ini$findPeaks$method %>% as.character
    MetabolomiQCsR.env$findPeaks$snthr                         <<- ini$findPeaks$snthr %>% as.numeric
    MetabolomiQCsR.env$findPeaks$ppm                           <<- ini$findPeaks$ppm %>% as.numeric
    MetabolomiQCsR.env$findPeaks$peakwidth                     <<- ini$findPeaks$peakwidth %>% str_split(",") %>% unlist %>% as.numeric
    MetabolomiQCsR.env$findPeaks$scanrange                     <<- if(ini$findPeaks$scanrange=="NULL"){NULL}else{ini$findPeaks$scanrange %>% str_split(",") %>% unlist %>% as.numeric}
    MetabolomiQCsR.env$findPeaks$prefilter                     <<- ini$findPeaks$prefilter %>% str_split(",") %>% unlist %>% as.numeric
    MetabolomiQCsR.env$findPeaks$integrate                     <<- ini$findPeaks$integrate %>% as.integer
    MetabolomiQCsR.env$findPeaks$verbose.columns               <<- ini$findPeaks$verbose.columns %>% as.logical
    MetabolomiQCsR.env$findPeaks$fitgauss                      <<- ini$findPeaks$fitgauss %>% as.logical
    
    
}



# Remove config environment on unload
.onDetach <- function(libpath = find.package("MetabolomiQCsR")) {
    rm(MetabolomiQCsR.env,envir = globalenv())
}
