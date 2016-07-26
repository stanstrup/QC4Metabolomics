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

