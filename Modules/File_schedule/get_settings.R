ini <- MetabolomiQCsR.env$general$settings_file %>% read.ini

#### Read ini file data into environment

MetabolomiQCsR.env$module_File_schedule$enabled_modules  <- ini %>%
                                                            list.match("module_.*") %>% 
                                                            list.filter(file_schedule == TRUE & enabled == TRUE) %>%
                                                            names


# cleanup
rm(ini)
