### R code from vignette source 'pcaMethods.Rnw'

###################################################
### code chunk number 1: pcaMethods.Rnw:102-114
###################################################
library(pcaMethods)
x <- c(-4,7); y <- c(-3,4)
distX <- rnorm(100, sd=0.3)*3
distY <- rnorm(100, sd=0.3) + distX * 0.3
mat <- cbind(distX, distY)
res <- pca(mat, nPcs=2, method="svd", center=F)
loading <- loadings(res)[1,]
grad <- loading[2] / loading[1]
if (grad < 0)
   grad <- grad * -1
lx <- c(-4,7)
ly <- c(grad * -4, grad * 7)


###################################################
### code chunk number 2: pcaMethods.Rnw:118-125
###################################################
par(mar=c(2, 3, 2, 2))
plot(x,y, type="n", xlab="", ylab="")
abline(v=0, col="dark gray", lwd = 2); abline(h=0, col = "dark gray", lwd = 2)
points(distX, distY, type = 'p', col = "blue")
lines(lx,ly, lwd = 2)
points(-1, -1 * grad + 0.5, pch = 19, col = "red", lwd=4)
points(6, 6 * grad + 0.5, pch = 19, col = "red", lwd=4)


###################################################
### code chunk number 3: pcaMethods.Rnw:253-255
###################################################
library(lattice)
library(pcaMethods)


###################################################
### code chunk number 4: pcaMethods.Rnw:258-261
###################################################
library(pcaMethods)
data(metaboliteData)
data(metaboliteDataComplete)


###################################################
### code chunk number 5: pcaMethods.Rnw:264-266
###################################################
md  <- prep(metaboliteData, scale="none", center=TRUE)
mdC  <- prep(metaboliteDataComplete, scale="none", center=TRUE)


###################################################
### code chunk number 6: pcaMethods.Rnw:271-277
###################################################
resPCA  <- pca(mdC, method="svd", center=FALSE, nPcs=5)
resPPCA  <- pca(md, method="ppca", center=FALSE, nPcs=5)
resBPCA  <- pca(md, method="bpca", center=FALSE, nPcs=5)
resSVDI  <- pca(md, method="svdImpute", center=FALSE, nPcs=5)
resNipals  <- pca(md, method="nipals", center=FALSE, nPcs=5)
resNLPCA <- pca(md, method="nlpca", center=FALSE, nPcs=5, maxSteps=300)


###################################################
### code chunk number 7: pcaMethods.Rnw:293-296
###################################################
sDevs <- cbind(sDev(resPCA), sDev(resPPCA), sDev(resBPCA), sDev(resSVDI), sDev(resNipals), sDev(resNLPCA))
matplot(sDevs, type = 'l', xlab="Eigenvalues", ylab="Standard deviation of PC", lwd=3)
legend(x="topright", legend=c("PCA", "PPCA", "BPCA", "SVDimpute","Nipals PCA","NLPCA"), lty=1:6, col=1:6, lwd=3)


###################################################
### code chunk number 8: pcaMethods.Rnw:308-311
###################################################
par(mfrow=c(1,2))
plot(loadings(resBPCA)[,1], loadings(resPCA)[,1], xlab="BPCA", ylab="classic PCA", main = "Loading 1")
plot(loadings(resBPCA)[,2], loadings(resPCA)[,2], xlab="BPCA", ylab="classic PCA", main = "Loading 2")


###################################################
### code chunk number 9: pcaMethods.Rnw:335-337
###################################################
q2SVDI <- Q2(resSVDI, mdC, fold=10)
q2PPCA <- Q2(resPPCA, mdC, fold=10)


###################################################
### code chunk number 10: pcaMethods.Rnw:339-349
###################################################
# PPCA does not converge / misestimate a value in very rare cases.
# This is a workaround to avoid that such a case will break the
# diagram displayed in the vignette.
# From the 2.0 release of bioconductor on, the convergence threshold
# for PPCA was lowert to 1e-5, this should make the method much more
# stable. So this workaround might be obsolete now...
# [nope it is not, ppca is unstable]
while( sum((abs(q2PPCA)) > 1) >= 1 ) {
    q2PPCA <- Q2(resPPCA, mdC, fold=10)
}


###################################################
### code chunk number 11: pcaMethods.Rnw:353-356
###################################################
q2 <- data.frame(Q2=c(drop(q2PPCA), drop(q2SVDI)), 
                 method=c("PPCA", "SVD-Impute")[gl(2, 5)], PC=rep(1:5, 2))
print(xyplot(Q2~PC|method, q2, ylab=expression(Q^2), type="h", lwd=4))


###################################################
### code chunk number 12: pcaMethods.Rnw:389-390
###################################################
errEsti <- kEstimate(md, method = "ppca", evalPcs=1:5, nruncv=1, em="nrmsep")


###################################################
### code chunk number 13: pcaMethods.Rnw:396-397
###################################################
barplot(drop(errEsti$eError), xlab="Loadings", ylab="NRMSEP (Single iteration)")


###################################################
### code chunk number 14: pcaMethods.Rnw:420-422
###################################################
barplot(drop(errEsti$variableWiseError[, which(errEsti$evalPcs == errEsti$bestNPcs)]), 
xlab="Incomplete variable Index", ylab="NRMSEP")


###################################################
### code chunk number 15: pcaMethods.Rnw:444-445
###################################################
slplot(resPCA)


###################################################
### code chunk number 16: pcaMethods.Rnw:455-456
###################################################
plotPcs(resPPCA, pc=1:3, scoresLoadings=c(TRUE, FALSE))


