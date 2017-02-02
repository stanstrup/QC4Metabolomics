## ----style, eval=TRUE, echo=FALSE, results="asis"---------------------------------------
BiocStyle::latex()

## ----openraw----------------------------------------------------------------------------
library(mzR)
library(msdata)

mzxml <- system.file("threonine/threonine_i2_e35_pH_tree.mzXML", 
                     package = "msdata")
aa <- openMSfile(mzxml) ## ramp, default backend

## ----get header information-------------------------------------------------------------
runInfo(aa)
instrumentInfo(aa)
header(aa,1)

## ----plotspectrum-----------------------------------------------------------------------
pl <- peaks(aa,10)
peaksCount(aa,10)
head(pl)
plot(pl[,1], pl[,2], type="h", lwd=1)

## ----close the file---------------------------------------------------------------------
close(aa)

## ----openid-----------------------------------------------------------------------------
library(mzR)
library(msdata)

file <- system.file("mzid", "Tandem.mzid.gz", package="msdata")
x <- openIDfile(file)

## ----metadata---------------------------------------------------------------------------
mzidInfo(x)

## ----psms0------------------------------------------------------------------------------
p <- psms(x)
colnames(p)

## ----psms1------------------------------------------------------------------------------
m <- modifications(x)
head(m)

## ----psms2------------------------------------------------------------------------------
scr <- score(x)
colnames(scr)

## ----label=sessioninfo, results='asis', echo=FALSE--------------------------------------
toLatex(sessionInfo())

