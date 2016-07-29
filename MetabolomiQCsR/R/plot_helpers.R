#' Make replacements in plotly tooltips
#'
#' @param plotly A \code{\link[plotly]{plotly}} object.
#' @param rep A named character vector. Names are the text to replace and the string is the replacement string.
#'
#' @return A \code{\link[plotly]{plotly}} object.
#' @export
#'

plotly_clean_tt <- function(plotly, rep){
    
    new_text <- plotly$data[[1]]$text
    
    for(i in seq_along(rep)){
        new_text <- gsub(names(rep)[i], rep[i], new_text, fixed=TRUE)
    }
    
    plotly$data[[1]]$text <- new_text
    
    return(plotly)
}
