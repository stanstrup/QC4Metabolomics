# Functions ---------------------------------------------------------------
# Check for new data every 10 s
std_cmp_tbl_read <- reactivePoll(10*1000, # every 10 s
                                 session=session,
                                 function(){ 
                                            # update after submit is clicked
                                            input$std_cmp_submit
                                            # update after delete is clicked
                                            input$std_cmp_delete
                                            # check same number of entries (new/deleted rows).
                                            a <- "SELECT COUNT(*) FROM std_compounds"      %>% dbGetQuery(pool, .) %>% as.numeric 
                                            #  Also check if updates.
                                            b <- "SELECT MAX(updated_at) FROM std_compounds" %>% {suppressWarnings(dbGetQuery(pool,.))}
                                            return(list(a,b))
                                           },
                                 function() "SELECT * FROM std_compounds ORDER BY cmp_id" %>% {suppressWarnings(dbGetQuery(pool,.))}
                                )



UpdateInputs <- function(data, session) {
  updateNumericInput(session,   "std_cmp_id",          value    = data %>% extract2("cmp_id")       )
  updateTextInput(session,   "std_cmp_name",           value    = data %>% extract2("cmp_name")     )
  updateSelectInput(session, "std_cmp_mode",           selected = data %>% extract2("mode")         )
  updateNumericInput(session,   "std_cmp_mz",          value    = data %>% extract2("cmp_mz")       )
  updateNumericInput(session,   "std_cmp_rt1",         value    = data %>% extract2("cmp_rt1")       )
  updateNumericInput(session,   "std_cmp_rt2",         value    = data %>% extract2("cmp_rt2")       )
  
  updateCheckboxInput(session, "std_cmp_enable",       value    =  data %>% extract2("enabled")     )
}


std_cmp_default_data <- data.frame(cmp_id=NA, cmp_name="",mode=NA,cmp_mz=NA,cmp_rt1=NA, cmp_rt2=NA  )




# Running logic -----------------------------------------------------------

# Select row in table -> show details in inputs
observeEvent(input$std_cmp_tbl_rows_selected, 
             {
                if (length(input$std_cmp_tbl_rows_selected) > 0) {
                    std_cmp_tbl_read() %>% 
                                            slice(input$std_cmp_tbl_rows_selected) %>% 
                                            UpdateInputs(session)
                    
                    updateActionButton(session, "std_cmp_submit", label="Update")
             }
    
})



# Press "New" button -> display empty record
observeEvent(input$std_cmp_new, {
    
     std_cmp_default_data %>% UpdateInputs(session)
    
     updateActionButton(session, "std_cmp_submit", label="Submit")
})


# Press "Delete" button -> delete from data
observeEvent(input$std_cmp_delete, 
             {
                con <- poolCheckout(pool)
                dbBegin(con)
                sql <- paste0("DELETE FROM std_compounds WHERE cmp_id=",input$std_cmp_id)
                res <- dbSendQuery(con,sql)
                res <- dbCommit(con)
                poolReturn(con)
                
                std_cmp_default_data %>% UpdateInputs(session)
                updateActionButton(session, "std_cmp_submit", label="Submit")
             }, 
             priority = 1
)



# Click "Submit" button -> save data
observeEvent(   input$std_cmp_submit,
                {
                    data <- data.frame(cmp_name= input$std_cmp_name   %>% as.character,
                                       mode    = input$std_cmp_mode   %>% as.character,
                                       cmp_mz  = input$std_cmp_mz     %>% as.numeric,
                                       cmp_rt1 = input$std_cmp_rt1    %>% as.numeric,
                                       cmp_rt2 = input$std_cmp_rt2    %>% as.numeric,
                                       enabled = input$std_cmp_enable %>% as.numeric
                                      )
                    
                    con <- poolCheckout(pool)
                    dbBegin(con)
                            
                    if (!is.na(input$std_cmp_id)) {
                        # update
                        sql <-  data %>% 
                                mutate_each(funs(as.character)) %>% 
                                gather %>% 
                                mutate(value = paste0("'",value,"'")) %>% 
                                unite(out,key,value, sep="=") %>% 
                                extract2("out") %>% 
                                paste(collapse=",") %>% 
                                paste0("UPDATE std_compounds SET ",.," WHERE cmp_id=",input$std_cmp_id) %>% 
                                gsub("'NA'","null",.)
                    } else {
                            sql <- sqlAppendTable(con, "std_compounds", data) # insert
                    }
                    
                res <- dbSendQuery(con,sql)
                res <- dbCommit(con)
                poolReturn(con)
                
                std_cmp_default_data %>% UpdateInputs(session)
                updateActionButton(session, "std_cmp_submit", label="Submit")
                
                }, 
                priority = 1
            )

  

# Display table -----------------------------------------------------------
output$std_cmp_tbl <- renderDataTable({

                                        std_cmp_tbl_read() %>% 
                                        mutate(enabled = as.logical(enabled)) %>% 
                                        datatable(colnames=c("Compound ID", "Compound Name", "Mode", "m/z", "RT 1", "RT 2", "Enabled?", "Changed"),
                                                  rownames = FALSE, 
                                                  selection = "single",
                                                  options=list(columnDefs = list(list(visible=FALSE, targets=c(7))))
                                                  ) %>% 
                                        formatRound(columns=c('cmp_mz'), digits=4) %>% 
                                        formatRound(columns=c('cmp_rt1'), digits=2)
    
                                     },
                                     server = FALSE

                                    )
