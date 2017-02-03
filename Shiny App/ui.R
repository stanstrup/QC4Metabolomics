shinyUI(           
        do.call(navbarPage, c(list("MetabolomiQCs"), 
                              lapply(seq_along(module_names), 
                                     function(i){    do.call(paste0(module_names[i],"UI"),list(id = paste0("name",i)))    }
                                     )
                              )
                )
                   
        )
