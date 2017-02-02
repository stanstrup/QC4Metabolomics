### R code from vignette source 'missingValues.Rnw'

###################################################
### code chunk number 1: missingValues.Rnw:43-44
###################################################
library(pcaMethods)


###################################################
### code chunk number 2: missingValues.Rnw:46-49
###################################################
data(metaboliteData)
mD <- metaboliteData
sum(is.na(mD))


###################################################
### code chunk number 3: missingValues.Rnw:52-54
###################################################
pc <- pca(mD, nPcs=3, method="ppca")
imputed <- completeObs(pc)


###################################################
### code chunk number 4: missingValues.Rnw:58-61
###################################################
data(metaboliteDataComplete)
mdComp <- metaboliteDataComplete
sum((mdComp[is.na(mD)] - imputed[is.na(mD)])^2) / sum(mdComp[is.na(mD)]^2)


###################################################
### code chunk number 5: missingValues.Rnw:64-66
###################################################
imputedNipals <- completeObs(pca(mD, nPcs=3, method="nipals"))
sum((mdComp[is.na(mD)] - imputedNipals[is.na(mD)])^2) / sum(mdComp[is.na(mD)]^2)


###################################################
### code chunk number 6: missingValues.Rnw:71-80
###################################################
library(Biobase)
data(sample.ExpressionSet)
exSet <- sample.ExpressionSet
exSetNa <- exSet
exprs(exSetNa)[sample(13000, 200)] <- NA
lost <- is.na(exprs(exSetNa))
pc <- pca(exSetNa, nPcs=2, method="ppca")
impExSet <- asExprSet(pc, exSetNa)
sum((exprs(exSet)[lost] - exprs(impExSet)[lost])^2) / sum(exprs(exSet)[lost]^2)


