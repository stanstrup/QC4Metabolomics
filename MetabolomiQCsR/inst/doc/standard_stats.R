## ----setup, include=FALSE------------------------------------------------
library(svglite)
knitr::opts_chunk$set(echo = TRUE, fig.align = "center", dev='svglite')

## ----libraries, message=FALSE, warning = FALSE---------------------------
library(knitr)
library(xcms)
library(tools)
library(readr)
library(MetabolomiQCsR)
library(listviewer) # https://github.com/timelyportfolio/listviewer
library(purrr)
library(magrittr)
library(dplyr)
library(massageR)
library(tidyr)

## ----settings------------------------------------------------------------
settings <- list()

settings$xcmsRaw$profparam          <- list(step=0.005)

settings$std_match$ppm                <- 100 # this needs to be quite large for this strategy to work. Only scans inside this is used AFAIK. The centwave ppm setting will limit appropiately
settings$std_match$rt_tol             <- 0.25*60

settings$findPeaks$method             <- 'centWave'
settings$findPeaks$snthr              <- 10
settings$findPeaks$ppm                <- 30
settings$findPeaks$peakwidth          <- c(0.05*60,0.3*60)
settings$findPeaks$scanrange          <- NULL
settings$findPeaks$prefilter          <- c(3,1E3)
settings$findPeaks$integrate          <- 1
settings$findPeaks$verbose.columns    <- TRUE
settings$findPeaks$fitgauss           <- TRUE

jsonedit(settings)

## ----input files---------------------------------------------------------
files <- c("Z:/_Data/LIP1/0036_SevaMeal/mzML/0036_LIP1p_20160201_034_2_1_1.mzML",
           "Z:/_Data/LIP1/0036_SevaMeal/mzML/0036_LIP1p_20160201_057_36_1_1.mzML"
           )

## ----list of standards---------------------------------------------------
stds <- read_tsv("stds.tsv")
stds

## ----md5-----------------------------------------------------------------
raw %<>% mutate(md5 = path %>% as.character %>% md5sum %>% as.vector)

## ----merge tables--------------------------------------------------------
stds %>%    mutate(rt = rt*60) %>% 
            list %>% 
            rep(nrow(raw))%>% 
            data_frame(stds=.) %>% 
            bind_cols(raw,.) ->
data

rm(stds,raw)

## ----make ROIs-----------------------------------------------------------
data %<>%
            mutate(ROI = map2(raw,stds, ~ tbl2ROI(.y, 
                                            raw    = .x, 
                                            ppm    = settings$std_match$ppm, 
                                            rt_tol = settings$std_match$rt_tol
                                            )
                             )
                   )


data$ROI[[1]][[7]]

## ----findPeaks-----------------------------------------------------------

findPeaks_l <- lift_dl(findPeaks) # trick to make findPeaks accept a list of arguments.


data %<>% mutate(peakTable = map2(raw, ROI, ~ findPeaks_l(settings$findPeaks, object = .x, ROI.list = .y) %>% 
                                              as.data.frame %>% as.tbl
                                  )
                 )


data$peakTable[[1]] %>% kable

## ----matching peaks------------------------------------------------------

data %<>% mutate(peakTable = map(peakTable, ~ mutate(.x, row = 1:nrow(.x)))) # we add a row index we can match by later
             

data %<>% mutate(std_peaks = map2(stds, peakTable, ~ closest_match(.x, .y, settings$std_match$rt_tol,
                                                                  settings$std_match$ppm
                                                                  ) %>% 
                                                    data_frame(row = .) %>% 
                                                    bind_cols(.x) %>% 
                                                    left_join(.y, by = "row", suffix = c(".stds", ".peaks")) %>% 
                                                    mutate(found = ifelse(is.na(row),FALSE,TRUE)) %>% 
                                                    select(-row)
                                 )
                )



data$std_peaks[[1]] %>% kable

## ----approxfun-----------------------------------------------------------
data %<>% mutate(scan2rt_fun = map(raw, ~ approxfun(seq_along(.x@scantime),.x@scantime)))

## ----EIC-----------------------------------------------------------------
data %<>% mutate(EIC = map2(raw,std_peaks,
                           ~ get_EICs(.x, data_frame(mz_lower = .y$mz.stds - settings$findPeaks$ppm*.y$mz.stds*1E-6, 
                                                     mz_upper = .y$mz.stds + settings$findPeaks$ppm*.y$mz.stds*1E-6)
                                      )   
                           )
                )


## ----flatten-------------------------------------------------------------
data_flat <-    data %>% 
                select(file,polarity,raw,md5,std_peaks,path,scan2rt_fun) %>% 
                unnest(std_peaks, .drop = FALSE) %>% 
                bind_cols(data_frame(EIC=unlist(data$EIC,recursive = FALSE))) # we cannot just unnest the EICs so we do it manally and re-add them

data_flat %>% select(-scan2rt_fun, -raw, -EIC) %>% slice(1:12) %>% kable

## ----deviations----------------------------------------------------------

data_flat %<>% mutate(mz_dev = ((mz.peaks - mz.stds)/mz.stds)*1E6 ) %>% 
               mutate(rt_dev = rt.peaks - rt.stds , rt_dev_min = rt_dev/60)

## ----FWHM----------------------------------------------------------------
data_flat %<>% rowwise %>% 
               mutate(FWHM_scan  = 2*sqrt(2*log(2))*sigma) %>% 
               mutate(FWHM_start = (scpos - FWHM_scan/2) %>% scan2rt_fun ) %>%
               mutate(FWHM_end   = (scpos + FWHM_scan/2) %>% scan2rt_fun ) %>% 
               mutate(FWHM       =  FWHM_end - FWHM_start ) %>%
               mutate(FWHM_dp    =  scmax - scmin + 1 ) %>% # data points
               ungroup %>% 
               select(-FWHM_scan, -FWHM_start, -FWHM_end)

## ----factors-------------------------------------------------------------

data_flat %<>% mutate(TF =  map2_dbl(EIC,rt.peaks, ~ peak_factor(.x,.y,factor="TF"))) %>% 
               mutate(ASF = map2_dbl(EIC,rt.peaks, ~ peak_factor(.x,.y,factor="ASF")))


## ----output--------------------------------------------------------------
data_flat %>% select(-scan2rt_fun, -raw, -EIC) %>% slice(1:12) %>% kable

