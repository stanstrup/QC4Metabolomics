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

## ----best match----------------------------------------------------------
closest_match <- function(a,b, rt_tol, mz_ppm, rt_col = "rt", mz_col = "mz"){
    
    indices <- rep_len(as.numeric(NA), nrow(a))
    
    b_mz <- b %>% extract2(mz_col)
    b_rt <- b %>% extract2(rt_col)
        
    for(i in 1:nrow(a)){
        
        a_mz <- a %>% slice(i) %>% extract2(mz_col)
        a_rt <- a %>% slice(i) %>% extract2(rt_col)
        
        
        idx <-  abs(a_rt-b_rt) < rt_tol & 
               (abs(a_mz-b_mz)/a_mz)*1E6 <  mz_ppm
        
        # no match is found
        if(sum(idx)==0){ next } # we filled the vector with NA so we don't need to do anyting
        
        # 1 match is found
        if(sum(idx)==1){
            indices[i] <- which(idx) 
            next
            }
        
        # More than one match is found. RT wil decide
        if(sum(idx)>1){
            idx2       <- which.min(abs(a_rt-b_rt[idx]))
            indices[i] <- which(idx)[idx2]
            next
            }
            
    }
    
    return(indices)
}



## ----settings------------------------------------------------------------
settings <- list()

settings$xcmsRaw$profparam          <- list(step=0.005)

settings$std_match$ppm                <- 20
settings$std_match$rt_tol             <- 0.25*60

settings$findPeaks$method             <- 'centWave'
settings$findPeaks$snthr              <- 10
settings$findPeaks$ppm                <- 20
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

## ------------------------------------------------------------------------
stds <- read_tsv("stds.tsv")
stds

## ----read raw files------------------------------------------------------
raw <- xcmsRaw_to_tbl(files, profparam = settings$xcmsRaw$profparam)

raw

## ----md5-----------------------------------------------------------------
raw %<>% mutate(md5 = path %>% as.character %>% md5sum %>% as.vector)

## ----make ROIs-----------------------------------------------------------

attr_rem <- function(x, which) {
    attr(x, which) <- NULL
    return(x)
}

settings$findPeaks$ROI.list <-   
             stds %>% 
             rowwise %>% 
             transmute(mz        = mz, # not used!
                       mzmin     = mz - settings$std_match$ppm * mz * 1E-6, 
                       mzmax     = mz + settings$std_match$ppm * mz * 1E-6,
                       scmin     = which.min(abs((rt*60-settings$std_match$rt_tol)-raw$raw[[1]]@scantime)),
                       scmax     = which.min(abs((rt*60+settings$std_match$rt_tol)-raw$raw[[1]]@scantime)),
                       length    = -1, # not used!
                       intensity = -1  # not used!
                       ) %>%
             ungroup %>% 
        
             by_row(as.list) %>% 
             mutate( .out = map(.out, ~ attr_rem(.x,"indices"))) %>% # we get some indices attribute. Dunno why. But lets remove it.
             extract2(".out")


settings$findPeaks$ROI.list[[7]]

## ----findPeaks-----------------------------------------------------------

peakTable <- settings$findPeaks %>% 
             lift_dl(findPeaks, object = raw$raw[[1]])() %>% 
             as.data.frame %>% as.tbl %>% 
             arrange(mz) %>% 
             mutate_each(funs(./60),rt,rtmin,rtmax)

peakTable %>% kable

## ------------------------------------------------------------------------
peakTable %<>% mutate(row = 1:n())

stds %<>% closest_match(peakTable,settings$std_match$rt_tol/60,settings$std_match$ppm) %>% 
         data_frame(row = .) %>% 
         bind_cols(stds)

stds %<>% left_join(peakTable, by = "row", suffix = c(".stds", ".peaks")) %>% 
          mutate(found = ifelse(is.na(row),FALSE,TRUE)) %>% 
          select(-row)

stds %>% kable

