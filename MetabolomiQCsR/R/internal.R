selectively_suppress_warnings <- function(.f, pattern) {
  force(.f)  # ensure .f is evaluated once
  function(...) {
    withCallingHandlers(
      .f(...),
      warning = function(w) {
        if (grepl(pattern, conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )
  }
}
