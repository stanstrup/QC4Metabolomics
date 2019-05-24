shinyServer(function(input, output, session) {

    # Modules
    lapply(seq_along(module_names), 
           function(i){ callModule(get(module_names[i]), paste0("name",i))
                      }
           )

})



