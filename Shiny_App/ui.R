#from https://stackoverflow.com/questions/40604394/search-field-in-shiny-navbarpage
navbarPageWithInputs <- function(..., inputs) {
  navbar <- navbarPage(...)
  form <- tags$form(class = "navbar-form", style="float: right;", inputs)
  navbar[[3]][[1]]$children[[1]] <- htmltools::tagAppendChild(
    navbar[[3]][[1]]$children[[1]], form)
  navbar
}

 
shinyUI(           
        do.call(navbarPageWithInputs, c(list("MetabolomiQCs"),
							  inputs=list(uiOutput("global_instruments_select_ui")),
                              lapply(seq_along(module_names), 
                                     function(i){    do.call(paste0(module_names[i],"UI"),list(id = paste0("name",i)))    }
                                     ) %>% unlist(recursive=FALSE)
                              )
                )
                   
        )
