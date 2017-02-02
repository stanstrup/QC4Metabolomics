test.foldchange <- function(){
  
  
  nvars <- 1000
  nsamples <- 50
  sample_groups <- 5
  data <- replicate(nvars, runif(n=nsamples))
  
  f <- rep_len(1:sample_groups, nsamples)
  f <- LETTERS[f]
  
  aggr_FUN <- median
  combi_FUN <- ratio.w.invert
  
  
  
  change1 <- fold.change(MAT=data,f=f,aggr_FUN=aggr_FUN,combi_FUN=combi_FUN,method=1)
  change2 <- fold.change(MAT=data,f=f,aggr_FUN=aggr_FUN,combi_FUN=combi_FUN,method=2)
  change3 <- fold.change(MAT=data,f=f,aggr_FUN=aggr_FUN,combi_FUN=combi_FUN,method=3)
  change4 <- fold.change(MAT=data,f=f,aggr_FUN=aggr_FUN,combi_FUN=combi_FUN,method=4)
  change5 <- fold.change(MAT=data,f=f,aggr_FUN=aggr_FUN,combi_FUN=combi_FUN,method=5)
  change6 <- fold.change(MAT=data,f=f,aggr_FUN=aggr_FUN,combi_FUN=combi_FUN,method=6)
  
  
  checkEquals(change1,change2)
  checkEquals(change1,change3)
  checkEquals(change1,change4)
  checkEquals(change1,change6)
  

  
}

test.deactivation <- function()
{
  DEACTIVATED('Deactivating this test function')
}








