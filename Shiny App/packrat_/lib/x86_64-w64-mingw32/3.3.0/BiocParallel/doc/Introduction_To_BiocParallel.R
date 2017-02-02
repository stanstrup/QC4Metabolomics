## ----style, eval=TRUE, echo=FALSE, results="asis"---------------------------------------
BiocStyle::latex()

## ----biocLite, eval=FALSE---------------------------------------------------------------
#  source("http://bioconductor.org/biocLite.R")
#  biocLite("BiocParallel")

## ----BiocParallel-----------------------------------------------------------------------
library(BiocParallel)

## ----quickstart_FUN---------------------------------------------------------------------
FUN <- function(x) { round(sqrt(x), 4) }

## ----quickstart_registry----------------------------------------------------------------
registered()

## ----configure_registry, eval=FALSE-----------------------------------------------------
#  options(MulticoreParam=quote(MulticoreParam(workers=4)))

## ----quickstart_bplapply_default, eval=FALSE--------------------------------------------
#  bplapply(1:4, FUN)

## ----quickstart_snow--------------------------------------------------------------------
param <- SnowParam(workers = 2, type = "SOCK")
bplapply(1:4, FUN, BPPARAM = param)

## ----BiocParallelParam_SerialParam------------------------------------------------------
serialParam <- SerialParam()
serialParam

## ----BiocParallelParam_MulticoreParam---------------------------------------------------
multicoreParam <- MulticoreParam(workers = 8)
multicoreParam

## ----register_registered----------------------------------------------------------------
registered()

## ----register_bpparam-------------------------------------------------------------------
bpparam()

## ----register_BatchJobsParam------------------------------------------------------------
register(BatchJobsParam(workers = 10), default = TRUE)

## ----register_BatchJobsParam2-----------------------------------------------------------
names(registered())
bpparam()

## ----error-vignette, eval=FALSE---------------------------------------------------------
#  browseVignettes("BiocParallel")

## ----use_cases_data---------------------------------------------------------------------
library(RNAseqData.HNRNPC.bam.chr14)
fls <- RNAseqData.HNRNPC.bam.chr14_BAMFILES

## ----forking_gr, message=FALSE----------------------------------------------------------
library(GenomicAlignments) ## for GenomicRanges and readGAlignments()
gr <- GRanges("chr14", IRanges((1000:3999)*5000, width=1000))

## ----forking_param----------------------------------------------------------------------
param <- ScanBamParam(which=range(gr))

## ----forking_FUN------------------------------------------------------------------------
FUN <- function(fl, param) {
  gal <- readGAlignments(fl, param = param)
  sum(countOverlaps(gr, gal))
}

## ----forking_default_multicore----------------------------------------------------------
MulticoreParam()

## ----cluster_FUN------------------------------------------------------------------------
FUN <- function(fl, param, gr) {
  library(GenomicAlignments)
  gal <- readGAlignments(fl, param = param)
  sum(countOverlaps(gr, gal))
}

## ----cluster_snow_param-----------------------------------------------------------------
snow <- SnowParam(workers = 2, type = "SOCK")

## ----cluster_bplapply-------------------------------------------------------------------
bplapply(fls[1:3], FUN, BPPARAM = snow, param = param, gr = gr)

## ----ad_hoc_sock_snow_param-------------------------------------------------------------
hosts <- c("rhino01", "rhino01", "rhino02")
param <- SnowParam(workers = hosts, type = "SOCK")

## ----cluster-MPI-work, eval=FALSE-------------------------------------------------------
#  library(BiocParallel)
#  library(Rmpi)
#  FUN <- function(i) system("hostname", intern=TRUE)

## ----cluster-MPI, eval=FALSE------------------------------------------------------------
#  param <- SnowParam(mpi.universe.size() - 1, "MPI")
#  register(param)

## ----cluster-MPI-do, eval=FALSE---------------------------------------------------------
#  xx <- bplapply(1:100, FUN)
#  table(unlist(xx))
#  mpi.quit()

## ----cluster-MPI-bpstart, eval=FALSE----------------------------------------------------
#  param <- bpstart(SnowParam(mpi.universe.size() - 1, "MPI"))
#  register(param)
#  xx <- bplapply(1:100, FUN)
#  bpstop(param)
#  mpi.quit()

## ----cluster-BatchJobs, eval=FALSE------------------------------------------------------
#  ## define work to be done
#  FUN <- function(i) system("hostname", intern=TRUE)
#  
#  library(BiocParallel)
#  library(BatchJobs)
#  
#  ## register SLURM cluster instructions from the template file
#  funs <- makeClusterFunctionsSLURM("slurm.tmpl")
#  param <- BatchJobsParam(4, resources=list(ncpus=1),
#                          cluster.functions=funs)
#  register(param)
#  
#  ## do work
#  xx <- bplapply(1:100, FUN)
#  table(unlist(xx))

## ----devel-bplapply---------------------------------------------------------------------
system.time(x <- bplapply(1:3, function(i) { Sys.sleep(i); i }))
unlist(x)

## ----sessionInfo, results="asis"--------------------------------------------------------
toLatex(sessionInfo())

