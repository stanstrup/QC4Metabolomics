
ini <- MetabolomiQCsR.env$general$settings_file %>% read.ini



#### Read ini file data into environment

MetabolomiQCsR.env$ICMeter$user                              <- ini$module_ICMeter$user     %>% as.character
MetabolomiQCsR.env$ICMeter$pass                              <- ini$module_ICMeter$pass %>% as.character


# cleanup
rm(ini)
