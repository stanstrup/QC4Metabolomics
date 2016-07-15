# Read raw data (to list tbl) ---------------------------------------------
xcmsRaw_to_tbl <- function(files){
    require(xcms)
    require(dplyr)
    require(purrr)
    
    data_cont <- files %>% 
        data_frame(path = .) %>% as.tbl %>%                  # string to tbl
        mutate(file=basename(path)) %>% 
        mutate(raw   = map(.$path, xcmsRaw)  ) %>%           # read raw data
        mutate_each(funs(as.factor),path,file) %>% 
        mutate(polarity = map_chr(raw,extract_polarity)) %>% # get polarity for each raw data
        select(file,polarity,raw,path)                       # just re-arrange for readability
    
    return(data_cont)
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
