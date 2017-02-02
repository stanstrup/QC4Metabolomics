### R code from vignette source 'outliers.Rnw'

###################################################
### code chunk number 1: outliers.Rnw:59-60
###################################################
library(pcaMethods)


###################################################
### code chunk number 2: outliers.Rnw:62-66
###################################################
data(metaboliteDataComplete)
mdc          <- scale(metaboliteDataComplete, center=TRUE, scale=FALSE)
cond         <- runif(length(mdc)) < 0.05;
mdcOut       <- mdc; mdcOut[cond] <- 10


###################################################
### code chunk number 3: outliers.Rnw:69-72
###################################################
resSvd       <- pca(mdc, method = "svd", nPcs = 5, center = FALSE)
resSvdOut    <- pca(mdcOut, method = "svd", nPcs = 5, center = FALSE)
resRobSvd    <- pca(mdcOut, method = "robustPca", nPcs = 5, center = FALSE)


###################################################
### code chunk number 4: outliers.Rnw:76-79
###################################################
mdcNa        <- mdc;
mdcNa[cond]  <- NA
resPPCA      <- pca(mdcNa, method = "ppca", nPcs = 5, center = FALSE)


###################################################
### code chunk number 5: outliers.Rnw:87-96
###################################################
par(mfrow=c(2,2))
plot(loadings(resSvd)[,1], loadings(resSvdOut)[,1], 
xlab = "Loading 1 SVD", ylab = "Loading 1 SVD with outliers")
plot(loadings(resSvd)[,1], loadings(resRobSvd)[,1],
xlab = "Loading 1 SVD", ylab = "Loading 1 robustSVD with outliers")
plot(loadings(resSvd)[,1], loadings(resPPCA)[,1],
xlab = "Loading 1 SVD", ylab = "Loading 1 PPCA with outliers = NA")
plot(loadings(resRobSvd)[,1], loadings(resPPCA)[,1],
xlab = "Loading 1 roubst SVD with outliers", ylab = "Loading 1 svdImpute with outliers = NA")


