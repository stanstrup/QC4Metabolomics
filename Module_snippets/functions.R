# Read raw data (to list tbl) ---------------------------------------------
xcmsRaw_to_tbl <- function(files){
    require(xcms)
    require(dplyr)
    require(purrr)
    
    data <- files %>% 
        data_frame(path = .) %>% as.tbl %>%                  # string to tbl
        mutate(file=basename(path)) %>% 
        mutate(raw   = map(.$path, xcmsRaw)  ) %>%           # read raw data
        mutate_each(funs(as.factor),path,file) %>% 
        mutate(polarity = map_chr(raw,extract_polarity)) %>% # get polarity for each raw data
        select(file,polarity,raw,path)                       # just re-arrange for readability
    
    return(data)
}


# mz <- openMSfile(files[1],backend = "Ramp")
# runInfo(mz)
# header(mz)$polarity
# close(mz)





# Read polarity from xcms::xcmsRaw object ---------------------------------
extract_polarity <- function(xraw){
    
    pols          <- xraw@polarity
    pols_count    <- table(pols)
    pols_dominant <- names(pols_count)[which.max(pols_count)]
    
    return(pols_dominant)
    
}


# Get contamination list for a vector of polarities -----------------------

# relies on the QC4Metabolomics.env being found globally

get_cont_list <- function(polarity,type) {
    require(magrittr)
    require(dplyr)
    require(purrr)
    library(readr)
    library(RCurl)
    
    polarity_un <- unique(polarity)
    
    if(type=="URL"){
    cont_list <- QC4Metabolomics.env$target_cont$cont_list$loc %>% 
        {data_frame(polarity = names(.),loc = as.character(.))} %>% 
        filter(polarity %in% polarity_un) %>% 
        mutate(cont_list = map_chr(loc, getURL)) %>% 
        mutate(cont_list = map(cont_list, read_tsv))
    }
    
    out <- polarity %>% 
        {data_frame(polarity=polarity)} %>% as.tbl %>% 
        left_join(cont_list, by="polarity") %>% 
        extract2("cont_list")
    
    return(out)
}




# gg contamination barplot to plotly --------------------------------------
# with fixed tooltip

cont_screen_gg2plotly <- function(x){
    require(magrittr)
    require(dplyr)
    require(plotly)
    
    gg <- plotly_build(x)
    
    gg$data[[1]]$text <- paste0("<b>Compound:</b> ",   x %>% extract2("data") %>% arrange(desc(EIC_median)) %>% extract2("comp_name") %>% as.character, "<br>",
                               "<b>EIC Median:</b> ", x %>% extract2("data") %>% arrange(desc(EIC_median)) %>% extract2("EIC_median") %>% round(0)
    )
    
    return(gg)
}



get_EICs <- function(tbl){
require(xcms)
require(purrr)
require(plyr)
    

tbl %>%     
        mutate(EIC   = pmap(list(raw,mz_lower,mz_upper),   function(raw,lower,upper) rawEIC(raw, as.matrix(data.frame(mzmin=lower,mzmax=upper)))   )) %>% # get the EICs
        mutate(EIC   = map(EIC,  ~ do.call(cbind.data.frame,.) %>% as.tbl  )) %>%     # EICs are lists. make nice data.frame
        mutate(EIC   = map2(EIC,raw, function(EIC,raw) mutate(EIC,scan_rt = raw@scantime[EIC$scan]/60)   )) %>% # convert scans to retention times
        mutate(EIC_median   = map_dbl(EIC,  ~ median(.$intensity)   )) %>%  # get the median intensity of each EIC
        mutate(EIC_mean     = map_dbl(EIC,  ~ mean(.$intensity)   )) %>%    # get the median intensity of each EIC
        mutate(EIC_sd       = map_dbl(EIC,  ~ sd(.$intensity)   )) %>%      # get the sd intensity of each EIC
        mutate(EIC_max      = map_dbl(EIC,  ~ max(.$intensity)   )) %>%     # get the max intensity of each EIC
        mutate(EIC_max      = map_dbl(EIC,  ~ max(.$intensity)   )) ->      # get the max intensity of each EIC
out

return(out)
    
}
