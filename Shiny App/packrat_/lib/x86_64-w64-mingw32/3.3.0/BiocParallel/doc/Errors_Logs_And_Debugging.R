## ----style, eval=TRUE, echo=FALSE, results="asis"---------------------------------------
BiocStyle::latex()

## ----biocLite, eval=FALSE---------------------------------------------------------------
#  source("http://bioconductor.org/biocLite.R")
#  biocLite("BiocParallel")

## ----load-------------------------------------------------------------------------------
library(BiocParallel)

## ----errors_constructor-----------------------------------------------------------------
param <- SnowParam()
param

## ----errors_stopOnError-----------------------------------------------------------------
param <- SnowParam(2, stop.on.error = TRUE)
param
bpstopOnError(param) <- FALSE

## ----errors_6tasksA_stopOnError---------------------------------------------------------
X <- list(1, "2", 3, 4, 5, 6)
param <- SnowParam(3, tasks = length(X), stop.on.error = TRUE)

## ----errors_6tasksA_stopOnError_output--------------------------------------------------
res <- tryCatch({
    bplapply(X, sqrt, BPPARAM = param)
}, error=identity)
res
attr(res, "result")

## ----errors_6tasks_nonstopOnError-------------------------------------------------------
X <- list("1", 2, 3, 4, 5, 6)
param <- SnowParam(3, tasks = length(X), stop.on.error = FALSE)
res <- tryCatch({
    bplapply(X, sqrt, BPPARAM = param)
}, error=identity)
res
attr(res, "result")

## ----error_bptry------------------------------------------------------------------------
bptry({
    bplapply(X, sqrt, BPPARAM=param)
})

## ----errors_3tasksA_stopOnError---------------------------------------------------------
X <- list(1, 2, "3", 4, 5, 6)
param <- SnowParam(3, stop.on.error = TRUE)

## ----errors_3tasksA_stopOnError_output--------------------------------------------------
bptry(bplapply(X, sqrt, BPPARAM = param))

## ----errors_bpok_bplapply---------------------------------------------------------------
param <- SnowParam(2, stop.on.error=FALSE)
result <- bptry(bplapply(list(1, "2", 3), sqrt, BPPARAM=param))

## ----errors_bpok------------------------------------------------------------------------
bpok(result)

## ----errors_traceback-------------------------------------------------------------------
tail(attr(result[[which(!bpok(result))]], "traceback"))

## ----redo_error-------------------------------------------------------------------------
X <- list(1, "2", 3)
param <- SnowParam(2, stop.on.error=FALSE)
result <- bptry(bplapply(X, sqrt, BPPARAM=param))
result

## ----errors_BPREDO_input----------------------------------------------------------------
X.redo <- list(1, 2, 3)

## ----redo_run---------------------------------------------------------------------------
bplapply(X.redo, sqrt, BPREDO=result, BPPARAM=param)

## ----logs_constructor-------------------------------------------------------------------
param <- SnowParam(stop.on.error=FALSE)
param

## ----logs_accessors---------------------------------------------------------------------
bplog(param) <- TRUE
bpthreshold(param) <- "TRACE"
param

## ----logs_bplapply----------------------------------------------------------------------
tryCatch({
    bplapply(list(1, "2", 3), sqrt, BPPARAM = param)
}, error=function(e) invisible(e))

## ----logs_FUN---------------------------------------------------------------------------
FUN <- function(i) {
  futile.logger::flog.debug(paste("value of 'i':", i))

  if (!length(i)) {
      futile.logger::flog.warn("'i' has length 0")
      NA
  } else if (!is(i, "numeric")) {
      futile.logger::flog.debug("coercing 'i' to numeric")
      as.numeric(i)
  } else {
      i
  }
}

## ----logs_FUN_WARN----------------------------------------------------------------------
param <- SnowParam(2, log = TRUE, threshold = "WARN", stop.on.error=FALSE)
result <- bplapply(list(1, "2", integer()), FUN, BPPARAM = param)
simplify2array(result)

## ----logs_FUN_DEBUG---------------------------------------------------------------------
param <- SnowParam(2, log = TRUE, threshold = "DEBUG", stop.on.error=FALSE)
result <- bplapply(list(1, "2", integer()), FUN, BPPARAM = param)
simplify2array(result)

## ----timeout_constructor----------------------------------------------------------------
param <- SnowParam(timeout = 20, stop.on.error=FALSE)
param

## ----timeout_setter---------------------------------------------------------------------
param <- SnowParam(timeout = 2, stop.on.error=FALSE)
fun <- function(i) {
  Sys.sleep(i)
  i
}
bptry(bplapply(1:3, fun, BPPARAM = param))

## ----debug_sqrtabs----------------------------------------------------------------------
fun1 <- function(x) {
    v <- abs(x)
    sapply(1:length(v), function(i) sqrt(v[i]))
}

## ----debug_fun1_debug-------------------------------------------------------------------
fun2 <- function(x) {
    v <- abs(x)
    futile.logger::flog.debug(
      paste0("'x' = ", paste(x, collapse=","), ": length(v) = ", length(v))
    )
    sapply(1:length(v), function(i) {
      futile.logger::flog.info(paste0("'i' = ", i))
      sqrt(v[i])
    })
}

## ----debug_param_debug------------------------------------------------------------------
param <- SnowParam(3, log = TRUE, threshold = "DEBUG")

## ----debug_DEBUG------------------------------------------------------------------------
res <- bplapply(list(c(1,3), numeric(), 6), fun2, BPPARAM = param)
res

## ----debug_sqrt-------------------------------------------------------------------------
res <- bptry({
    bplapply(list(1, "2", 3), sqrt,
             BPPARAM = SnowParam(3, stop.on.error=FALSE))
})
result

## ----debug_sqrt_wrap--------------------------------------------------------------------
fun3 <- function(i) sqrt(i)

## ----sessionInfo, results="asis"--------------------------------------------------------
toLatex(sessionInfo())

