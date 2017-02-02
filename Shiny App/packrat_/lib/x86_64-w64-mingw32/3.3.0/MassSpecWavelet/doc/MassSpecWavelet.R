### R code from vignette source 'MassSpecWavelet.Rnw'

###################################################
### code chunk number 1: MassSpecWavelet.Rnw:45-46
###################################################
library(MassSpecWavelet)


###################################################
### code chunk number 2: MassSpecWavelet.Rnw:50-51
###################################################
data(exampleMS)


###################################################
### code chunk number 3: MassSpecWavelet.Rnw:55-57
###################################################
scales <- seq(1, 64, 2)
 wCoefs <- cwt(exampleMS, scales = scales, wavelet = "mexh")


###################################################
### code chunk number 4: MassSpecWavelet.Rnw:63-70
###################################################
## Plot the 2-D CWT coefficients as image (It may take a while!)
xTickInterval <- 1000
plotRange <- c(5000, 11000)
image(plotRange[1]:plotRange[2], scales, wCoefs[plotRange[1]:plotRange[2],], col=terrain.colors(256), axes=FALSE, xlab='m/z index', ylab='CWT coefficient scale', main='CWT coefficients')
axis(1, at=seq(plotRange[1], plotRange[2], by=xTickInterval))
axis(2, at=c(1, seq(10, 64, by=10)))
box()


###################################################
### code chunk number 5: MassSpecWavelet.Rnw:81-86
###################################################
## Attach the raw spectrum as the first column
wCoefs <- cbind(as.vector(exampleMS), wCoefs)
colnames(wCoefs) <- c(0, scales)
localMax <- getLocalMaximumCWT(wCoefs)
    


###################################################
### code chunk number 6: MassSpecWavelet.Rnw:91-92
###################################################
plotLocalMax(localMax, wCoefs, range=plotRange)


###################################################
### code chunk number 7: MassSpecWavelet.Rnw:100-101
###################################################
ridgeList <- getRidge(localMax)


###################################################
### code chunk number 8: MassSpecWavelet.Rnw:105-106
###################################################
plotRidgeList(ridgeList,  wCoefs, range=plotRange)


###################################################
### code chunk number 9: MassSpecWavelet.Rnw:114-119
###################################################
SNR.Th <- 3
nearbyPeak <- TRUE
majorPeakInfo <- identifyMajorPeaks(exampleMS, ridgeList, wCoefs, SNR.Th = SNR.Th, nearbyPeak=nearbyPeak)
## Plot the identified peaks
peakIndex <- majorPeakInfo$peakIndex


###################################################
### code chunk number 10: MassSpecWavelet.Rnw:125-126
###################################################
plotPeak(exampleMS, peakIndex, range=plotRange, main=paste('Identified peaks with SNR >', SNR.Th)) 


###################################################
### code chunk number 11: MassSpecWavelet.Rnw:134-141
###################################################
data(exampleMS)
SNR.Th <- 3
nearbyPeak <- TRUE
peakInfo <- peakDetectionCWT(exampleMS, SNR.Th=SNR.Th, nearbyPeak=nearbyPeak)
majorPeakInfo = peakInfo$majorPeakInfo
peakIndex <- majorPeakInfo$peakIndex
plotRange <- c(5000, length(exampleMS))


###################################################
### code chunk number 12: MassSpecWavelet.Rnw:145-146
###################################################
plotPeak(exampleMS, peakIndex, range=plotRange, log='x', main=paste('Identified peaks with SNR >', SNR.Th)) 


###################################################
### code chunk number 13: MassSpecWavelet.Rnw:153-155
###################################################
	peakSNR <- majorPeakInfo$peakSNR
	allPeakIndex <- majorPeakInfo$allPeakIndex


###################################################
### code chunk number 14: MassSpecWavelet.Rnw:160-165
###################################################
	plotRange <- c(5000, 36000)
	selInd <- which(allPeakIndex >= plotRange[1] & allPeakIndex < plotRange[2])
	plot(allPeakIndex[selInd], peakSNR[selInd], type='h', xlab='m/z Index', ylab='Signal to Noise Ratio (SNR)', log='x')
	points(peakIndex, peakSNR[names(peakIndex)], type='h', col='red')
	title('Signal to Noise Ratio (SNR) of the peaks (CWT method)')


###################################################
### code chunk number 15: MassSpecWavelet.Rnw:176-177
###################################################
        betterPeakInfo <- tuneInPeakInfo(exampleMS, majorPeakInfo)


###################################################
### code chunk number 16: MassSpecWavelet.Rnw:181-184
###################################################
	plotRange <- c(5000, 11000)
        	plot(plotRange[1]:plotRange[2], exampleMS[plotRange[1]:plotRange[2]], type='l', log='x', xlab='m/z Index', ylab='Intensity')
        	abline(v=betterPeakInfo$peakCenterIndex, col='red')


