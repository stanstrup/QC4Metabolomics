# Establish connection to get new files -----------------------------------------------
log_source <- "Warner"

pool <- dbPool_MetabolomiQCs(30)


# Do nothing if no rules defined --------------------------------------
rules_count <- paste0("SELECT COUNT(*) from warner_rules") %>% dbGetQuery(pool,.) %>% as.numeric

if(rules_count==0){
    write_to_log("No rules defined for Warner to work on", cat = "info", source = log_source, pool = pool)
    message("No rules defined. Quitting.")
    
    # close connections
    poolClose(pool)
    
    # If no rules found quit the process. Else do rest of script
    quit(save="no")
}



# extract rules and relevant violators ------------------------------------
rules <-  "SELECT
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
              {suppressWarnings(dbGetQuery(pool,.))} %>% 
              as_tibble %>% 
              rename(warner_rules.value = "value")


get_data_matching_rules <- function(stat_id, use_abs_value, instrument, operator, value){
  
glue("
     SELECT file_schedule.*, 
            std_stat_data.cmp_id,
            std_stat_data.found, 
            std_stat_data.value,
            file_info.project,
            file_info.mode,
            file_info.sample_id,
            file_info.time_run,
            files.path
     FROM file_schedule
     INNER JOIN std_stat_data 
     ON file_schedule.file_md5=std_stat_data.file_md5
     INNER JOIN file_info 
     ON file_schedule.file_md5=file_info.file_md5
     INNER JOIN files 
     ON file_schedule.file_md5=files.file_md5
     WHERE (std_stat_data.stat_id = '{stat_id}' AND 
            {if_else(as.logical(use_abs_value),'ABS', '')}(std_stat_data.value) {operator} {value} AND
            file_info.instrument = '{instrument}' AND
            file_schedule.module = 'Warner' AND file_schedule.priority > 0
            )
     ORDER BY file_schedule.priority ASC, file_info.time_run DESC
     
     "
     ) %>% 
            dbGetQuery(pool,.) %>% 
            as_tibble

}




rule_violators <- rules %>% 
          mutate(data = pmap(list(stat_id, use_abs_value, instrument, operator, warner_rules.value), get_data_matching_rules)) %>% 
          unnest(cols = data) %>% 
            mutate(across(c(time_run, updated_at), ~as.POSIXct(., tz="UTC"))) %>% 
            mutate(across(c(enabled, use_abs_value, found), as.logical))



# Check if any on ignore list ---------------------------------------------
ignored <-  paste0("
                    SELECT * FROM files_ignore
                    "
                    ) %>% 
            dbGetQuery(pool,.) %>% 
            distinct() %>% 
            as_tibble %>% 
            mutate(ignore = TRUE)

rule_violators <- 
  left_join(rule_violators, ignored, by = c("path", "file_md5")) %>%
  mutate(ignore = if_else(!is.na(ignore),ignore,FALSE)) %>% 
  filter(!ignore) %>% 
  select(-ignore)


# Do nothing if nothing left is scheduled ---------------------------------
if(nrow(rule_violators)==0){
    # close connections
    poolClose(pool)
    
    # If no files found quit the process. Else do rest of script
    quit(save="no")
}





# Create email ------------------------------------------------------------
email_safe_table <- function(df, nested_headers = NULL) {
  # Format numbers and POSIXct for email
  df[] <- lapply(df, function(col) {
    if (is.numeric(col)) {
      format(col, big.mark = ",", scientific = FALSE, trim = FALSE, drop0trailing = TRUE)
    } else if (inherits(col, "POSIXct")) {
      # Convert POSIXct to formatted string (e.g., "YYYY-MM-DD HH:MM:SS")
      format(col, "%Y-%m-%d %H:%M:%S")
    } else {
      col
    }
  })
  
  # Helper: nested header rows with colspan
  make_header_row <- function(labels) {
    rle_labels <- rle(labels)
    cells <- mapply(function(label, span) {
      sprintf(
        "<th colspan='%d' style='border: 1px solid #ccc; padding: 8px; background-color: #f2f2f2;white-space: nowrap;'>%s</th>",
        span, label
      )
    }, rle_labels$values, rle_labels$lengths)
    
    paste0("<tr>", paste0(cells, collapse = ""), "</tr>")
  }

  # Build <thead>
  thead <- if (!is.null(nested_headers)) {
    paste0(
      sapply(nested_headers, make_header_row),
      collapse = "\n"
    )
  } else {
    paste0(
      "<tr>",
      paste(sprintf(
        "<th style='border: 1px solid #ccc; padding: 8px; background-color: #f2f2f2;white-space: nowrap;'>%s</th>",
        names(df)
      ), collapse = ""),
      "</tr>"
    )
  }

  # Build <tbody> with alternating row colors
  row_color <- function(i) ifelse(i %% 2 == 0, "#f9f9f9", "#ffffff")
  rows_html <- paste0(
    lapply(seq_len(nrow(df)), function(i) {
      row <- df[i, ]
      paste0(
        "<tr style='background-color:", row_color(i), "'>",
        paste(sprintf("<td style='border: 1px solid #ccc; padding: 8px;white-space: nowrap;'>%s</td>", row), collapse = ""),
        "</tr>"
      )
    }),
    collapse = "\n"
  )

  # Final HTML table
  htmltools::HTML(sprintf(
    "<table style='border-collapse: collapse; width: 100%%;'>
      <thead>%s</thead>
      <tbody>%s</tbody>
    </table>", thead, rows_html
  ))
}












headers <- list(
  c(rep("Rule", 6), rep("Observed",6)),
  c("Rule name", "Instrument", "Statistic", "Operator", "Threshold", "Use absolute value", "Value", "File run time", "File path")
)


date_time <- add_readable_time()


email <- compose_email(
  body = HTML(glue(
    "
    <p>The following files were flagged as violating one or more rules defined in QC4Metabolomics:</p>
    
    {rule_violators %>% 
    select(`Rule name` = rule_name, 
    Instrument = instrument, 
    Statistic  = stat_name,
    Operator = operator,
    `Threshold` = warner_rules.value,
    `Use absolute value` = use_abs_value,
    `Value` = value,
    `File run time` = time_run,
    `File path` = path
    
    ) %>% 
    email_safe_table(nested_headers = headers)}
    "
  )),
    footer = md(glue("Email sent on {date_time} by the Warner module from QC4Metabolomics."))
)



safe_smtp_send <- safely(smtp_send)

result <- email %>% 
  safe_smtp_send(
    from = Sys.getenv("QC4METABOLOMICS_module_Warner_email_from"),
    to = Sys.getenv("QC4METABOLOMICS_module_Warner_email_to"),
    subject = "Warnings from QC4Metabolomics",
    credentials = creds_envvar(
      user = Sys.getenv("QC4METABOLOMICS_module_Warner_email_user"),
      pass_envvar = "QC4METABOLOMICS_module_Warner_email_password",
      host = Sys.getenv("QC4METABOLOMICS_module_Warner_email_host"),
      port = Sys.getenv("QC4METABOLOMICS_module_Warner_email_port"),
      use_ssl = as.logical(Sys.getenv("QC4METABOLOMICS_module_Warner_email_use_ssl"))
    )
  )







# If email send -----------------------------------------------------------
if (is.null(result$error)) {
  message("Email sent successfully!")
  
  write_to_log(paste0("Successfully send warning email ",length(unique(rule_violators$path))," files."), cat = "info", source = log_source, pool = pool)
  
# Update schedule
    sql_data <- rule_violators %>% distinct(module) %>% mutate(priority = -1L)
    
    con <- poolCheckout(pool)
    dbBegin(con)
    
    res_pri <- vector("logical", nrow(sql_data))
    for(i in 1:nrow(sql_data)){
        sql_query <- paste0("UPDATE file_schedule SET priority='", sql_data$priority[i],"' WHERE (module='",sql_data$module[i],"')")
        dbSendQuery(con,sql_query)
        res_pri[i] <- dbCommit(con)
    }
    
    
    poolReturn(con)
    write_to_log(paste0("priority updated for all files."), cat = "info", source = log_source, pool = pool)


}



# If email NOT send -------------------------------------------------------
if (!is.null(result$error)) {
  write_to_log(paste0("Failed to send warning email: ", result$error$message), cat = "error", source = log_source, pool = pool)
}




# close connections
poolClose(pool)

