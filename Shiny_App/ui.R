#from https://stackoverflow.com/questions/40604394/search-field-in-shiny-navbarpage
navbarPageWithInputs <- function(..., inputs) {
  navbar <- navbarPage(...)
  form <- tags$form(class = "navbar-form", style="float: right; margin-bottom: 0px;", inputs)
  
  navbar[[4]][[1]]$children[[1]][[1]]$children[[1]]$children[[2]] <- htmltools::tagAppendChild(navbar[[4]][[1]]$children[[1]][[1]]$children[[1]]$children[[2]], form)
  navbar
}


tagList(

tags$head(
  tags$style(type="text/css", 
               "
                #inline label{ display: table-cell; text-align: center; vertical-align: middle; } 
                #inline .form-group { display: table-row;}
                #inline .selectize-control { width: 200px; margin: 0;}
               "
             )
),

          
do.call(navbarPageWithInputs, c(list("MetabolomiQCs"),
			                          inputs=list(uiOutput("global_instruments_select_ui")),
                                lapply(seq_along(module_names), 
                                       function(i){do.call(paste0(module_names[i],"UI"),list(id = paste0("name",i)))}
                                      )
                              )
        )
                   
)
