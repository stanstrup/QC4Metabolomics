#' Make replacements in plotly tooltips
#'
#' @param plotly A \code{\link[plotly]{plotly}} object.
#' @param rep A named character vector. Names are the text to replace and the string is the replacement string.
#'
#' @return A \code{\link[plotly]{plotly}} object.
#' @export
#'

plotly_clean_tt <- function(plotly, rep){
    
    for(f in seq_along(plotly$x$data)){
        
        new_text <- plotly$x$data[[f]]$text
        
        for(i in seq_along(rep)){
            new_text <- gsub(names(rep)[i], rep[i], new_text, fixed=TRUE)
        }
        
        plotly$x$data[[f]]$text <- new_text
    }
    
    return(plotly)
}
