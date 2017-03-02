
ini <- MetabolomiQCsR.env$general$settings_file %>% read.ini



#### Read ini file data into environment
MetabolomiQCsR.env$TrackCmp$xcmsRaw$profparam          <- ini$module_TrackCmp$xcmsRaw__profparam %>% as.numeric %>% {list(step=.)}

MetabolomiQCsR.env$TrackCmp$ROI$ppm                    <- ini$module_TrackCmp$ROI__ppm %>% as.numeric

MetabolomiQCsR.env$TrackCmp$findPeaks$method           <- ini$module_TrackCmp$findPeaks__method %>% as.character
MetabolomiQCsR.env$TrackCmp$findPeaks$snthr            <- ini$module_TrackCmp$findPeaks__snthr %>% as.numeric
MetabolomiQCsR.env$TrackCmp$findPeaks$ppm              <- ini$module_TrackCmp$findPeaks__ppm %>% as.numeric
MetabolomiQCsR.env$TrackCmp$findPeaks$peakwidth        <- ini$module_TrackCmp$findPeaks__peakwidth %>% str_split(",") %>% unlist %>% as.numeric
MetabolomiQCsR.env$TrackCmp$findPeaks$scanrange        <- if(ini$module_TrackCmp$findPeaks__scanrange=="NULL"){NULL}else{ini$module_TrackCmp$findPeaks__scanrange %>% str_split(",") %>% unlist %>% as.numeric}
MetabolomiQCsR.env$TrackCmp$findPeaks$prefilter        <- ini$module_TrackCmp$findPeaks__prefilter %>% str_split(",") %>% unlist %>% as.numeric
MetabolomiQCsR.env$TrackCmp$findPeaks$integrate        <- ini$module_TrackCmp$findPeaks__integrate %>% as.integer
MetabolomiQCsR.env$TrackCmp$findPeaks$verbose.columns  <- ini$module_TrackCmp$findPeaks__verbose.columns %>% as.logical
MetabolomiQCsR.env$TrackCmp$findPeaks$fitgauss         <- ini$module_TrackCmp$findPeaks__fitgauss %>% as.logical

MetabolomiQCsR.env$TrackCmp$std_match$ppm              <- ini$module_TrackCmp$std_match__ppm %>% as.numeric
MetabolomiQCsR.env$TrackCmp$std_match$rt_tol           <- ini$module_TrackCmp$std_match__rt_tol %>% as.numeric


# cleanup
rm(ini)
