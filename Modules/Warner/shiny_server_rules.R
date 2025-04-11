# Functions ---------------------------------------------------------------
# Check for new data every 10 s
warner_tbl_read <- reactivePoll(10*1000, # every 10 s
                                 session=session,
                                 function(){ 
                                            # update after submit is clicked
                                            input$warner_submit
                                            # update after delete is clicked
                                            input$warner_delete
                                            # check same number of entries (new/deleted rows).
                                            a <- "SELECT COUNT(*) FROM warner_rules"      %>% dbGetQuery(pool, .) %>% as.numeric 
                                            #  Also check if updates.
                                            b <- "SELECT MAX(updated_at) FROM warner_rules" %>% {suppressWarnings(dbGetQuery(pool,.))}
                                            return(list(a,b))
                                           },
                                 function(){
                                            "SELECT
                                              warner_rules.rule_id,
                                              warner_rules.rule_name,
                                              warner_rules.instrument,
                                              warner_stat_types.stat_name,
                                              warner_rules.stat_id,
                                              warner_rules.operator,
                                              warner_rules.value,
                                              warner_rules.use_abs_value,
                                              warner_rules.enabled,
                                              warner_rules.updated_at
                                            FROM warner_rules
                                            JOIN warner_stat_types ON warner_rules.stat_id = warner_stat_types.stat_id
                                            ORDER BY warner_rules.rule_id;" %>% 
                                            {suppressWarnings(dbGetQuery(pool,.))}
                                           }
                                )



UpdateInputs <- function(data, session) {

  updateNumericInput(session, "warner_rule_id",    value    = data %>% extract2("rule_id")       )
  updateTextInput(session,    "warner_rule_name",  value    = data %>% extract2("rule_name")     )
  updateTextInput(session,    "warner_instrument", value    = data %>% extract2("instrument")     )
  updateSelectInput(session,  "warner_stat",       selected = setNames(data$stat_id, data$stat_name)         )
  updateSelectInput(session,  "warner_operator",   selected = data %>% extract2("operator")       )
  updateNumericInput(session, "warner_value",      value    = data %>% extract2("value")       )
  updateCheckboxInput(session,"warner_use_abs",    value    = data %>% extract2("use_abs_value")       )
  
  updateCheckboxInput(session,"warner_enable",     value    =  data %>% extract2("enabled")     )
}


warner_default_data <- data.frame(rule_id=NA, rule_name="",instrument = "", stat_id=NA,operator=NA,value=NA, use_abs_value=TRUE  )



# Elements ----------------------------------------------------------------
output$warner_stat_ui <- renderUI({
        ns <- session$ns

        stat_type_choices <- "SELECT * FROM warner_stat_types;" %>% 
          {suppressWarnings(dbGetQuery(pool,.))} %>% 
          {setNames(.$stat_id, .$stat_name)}
        
        selectInput(   ns("warner_stat"),     "Statistic", choices = stat_type_choices)

})




# Running logic -----------------------------------------------------------

# Select row in table -> show details in inputs
observeEvent(input$warner_tbl_rows_selected, 
             {
                if (length(input$warner_tbl_rows_selected) > 0) {
                    warner_tbl_read() %>% 
                                            slice(input$warner_tbl_rows_selected) %>% 
                                            UpdateInputs(session)
                    
                    updateActionButton(session, "warner_submit", label="Update")
             }
    
})



# Press "New" button -> display empty record
observeEvent(input$warner_new, {
    
     warner_default_data %>% UpdateInputs(session)
    
     updateActionButton(session, "warner_submit", label="Submit")
})


# Press "Delete" button -> delete from data
observeEvent(input$warner_delete, 
             {
                con <- poolCheckout(pool)
                dbBegin(con)
                sql1 <- paste0("DELETE FROM warner_rules WHERE rule_id=",input$warner_rule_id)
                sql2 <- paste0("DELETE FROM warner_log   WHERE rule_id=",input$warner_rule_id)
                res <- dbSendQuery(con,sql1)
                res <- dbSendQuery(con,sql2)
                res <- dbCommit(con)
                poolReturn(con)
                
                warner_default_data %>% UpdateInputs(session)
                updateActionButton(session, "warner_submit", label="Submit")
             }, 
             priority = 1
)



# Click "Submit" button -> save data
observeEvent(   input$warner_submit,
                {

                  
                    data <- data.frame(rule_id       =  input$warner_rule_id     %>% as.numeric,
                                       rule_name     =  input$warner_rule_name   %>% as.character,
                                       instrument    =  input$warner_instrument  %>% as.character,
                                       stat_id       =  input$warner_stat        %>% as.character,
                                       operator      =  input$warner_operator    %>% as.character,
                                       value         =  input$warner_value       %>% as.numeric,
                                       use_abs_value =  input$warner_use_abs     %>% as.numeric,
                                       enabled       =  input$warner_enable      %>% as.numeric
                                      )
                    

                    con <- poolCheckout(pool)
                    dbBegin(con)
                            
                    if (!is.na(input$warner_rule_id)) {
                        # update
                        sql <-  data %>% 
                                mutate(across(everything(), as.character)) %>% 
                                gather(value = "value_col") %>% 
                                mutate(value_col = paste0("'",value_col,"'")) %>% 
                                unite(out,key,value_col, sep="=") %>% 
                                extract2("out") %>% 
                                paste(collapse=",") %>% 
                                paste0("UPDATE warner_rules SET ",.," WHERE rule_id=",input$warner_rule_id) %>% 
                                gsub("'NA'","null",.)
                    } else {
                            sql <- sqlAppendTable(con, "warner_rules", data) # insert
                    }
                    
                res <- dbSendQuery(con,sql)
                res <- dbCommit(con)
                poolReturn(con)
                
                warner_default_data %>% UpdateInputs(session)
                updateActionButton(session, "warner_submit", label="Submit")
                
                }, 
                priority = 1
            )

  

# Display table -----------------------------------------------------------
output$warner_tbl <- renderDataTable({
  
                                        warner_tbl_read() %>% 
                                        mutate(enabled = as.logical(enabled)) %>% 
                                        select(rule_id, rule_name, instrument, stat_name, operator, value, use_abs_value, enabled, updated_at) %>% 
                                        datatable(colnames=c("Rule ID", "Rule Name", "Instrument", "Statistic", "Operator", "Value", "Use absolute value?", "Enabled?", "Changed"),
                                                  rownames = FALSE, 
                                                  selection = "single"#,
                                                 # options=list(columnDefs = list(list(visible=FALSE, targets=c(7))))
                                                  )
    
                                     },
                                     server = FALSE

                                    )


