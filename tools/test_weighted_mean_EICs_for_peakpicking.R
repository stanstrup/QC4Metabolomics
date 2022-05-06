library(xcms)
library(MSnbase)
library(dplyr)
library(purrr)
library(tidyr)
library(ggplot2)


data <- readMSData(list.files("i:/SCIENCE-NEXS-NyMetabolomics/Projects/Marlou Dirks.pro/First run/mzML/", ".*\\.mzML$", full.names = TRUE), mode = "onDisk")
data <- data |>
        filterRt(c(4.5*60, 5*60)) |>
        filterMz(c(521, 523))


cwp <- CentWaveParam(peakwidth = c(2, 10), ppm = 200, integrate = 2)
cwp30 <- CentWaveParam(peakwidth = c(2, 10), ppm = 30, integrate = 2)




options(MZFUN = "getMZ")
data_old <- findChromPeaks(data, cwp)
data_old30 <- findChromPeaks(data, cwp30)



options(MZFUN = "getWeightedMZ")
data_new <- findChromPeaks(data, cwp)
data_new30 <- findChromPeaks(data, cwp30)



data_old %>% chromPeaks() %>% as_tibble # 1,543 peaks

data_new %>% chromPeaks() %>% as_tibble # 1,433 peaks


file <- 15
idx_old <- 38
idx_new <- 35



a <- data_old |>
        filterFile(file) |>
        filterRt(chromPeaks(data_old)[idx_old, c("rtmin", "rtmax")] + c(-0, 0)) |>
        filterMz(chromPeaks(data_old)[idx_old, c("mzmin", "mzmax")] + c(-0.02, 0.02))

plot(a, type = "XIC")
abline(h = 522.3554, col = "green", lwd = 3)
abline(h = chromPeaks(data_old)[idx_old, c("mz")], col = "red")
abline(h = chromPeaks(data_new)[idx_new, c("mz")], col = "blue", lty = 2)







b <- data_new |>
filterFile(file) |>
filterRt(chromPeaks(data_new)[idx_new, c("rtmin", "rtmax")] + c(-0, 2)) |>
filterMz(chromPeaks(data_new)[idx_new, c("mzmin", "mzmax")] + c(-0.02, 0.02))

plot(b, type = "XIC")
abline(h = 522.3554, col = "green", lwd = 3)
abline(h = chromPeaks(data_old)[idx_old, c("mz")], col = "red")
abline(h = chromPeaks(data_new)[idx_new, c("mz")], col = "blue", lty = 2)




# Check consistency over files --------------------------------------------


# get maxo peak from each file. plot old and new in different colors. add theoretical


max_maxo_old <- data_old %>% 
                  chromPeaks() %>% 
                  as_tibble %>% 
                  group_by(sample) %>% 
                  arrange(desc(maxo)) %>% 
                  slice(1) %>% 
                  ungroup



max_maxo_new <- data_new %>% 
                  chromPeaks() %>% 
                  as_tibble %>% 
                  group_by(sample) %>% 
                  arrange(desc(maxo)) %>% 
                  slice(1) %>% 
                  ungroup


bind_rows(old = max_maxo_old, new = max_maxo_new, .id = "algo") %>% 
  filter(mz>522) %>% 
  ggplot(aes(sample, mz, col = algo)) +
  geom_hline(yintercept =  522.3554, col = "green", size = 1) +
  geom_point() +
  theme_bw()
  



# Redo everything with 30ppm data -----------------------------------------


file <- 15
idx_old <- 35
idx_new <- 35


a <- data_old30 |>
        filterFile(file) |>
        filterRt(chromPeaks(data_old30)[idx_old, c("rtmin", "rtmax")] + c(-0, 0)) |>
        filterMz(chromPeaks(data_old30)[idx_old, c("mzmin", "mzmax")] + c(-0.02, 0.02))

plot(a, type = "XIC")
abline(h = 522.3554, col = "green", lwd = 3)
abline(h = chromPeaks(data_old30)[idx_old, c("mz")], col = "red")
abline(h = chromPeaks(data_new30)[idx_new, c("mz")], col = "blue", lty = 2)





b <- data_new30 |>
filterFile(file) |>
filterRt(chromPeaks(data_new30)[idx_new, c("rtmin", "rtmax")] + c(-0, 0)) |>
filterMz(chromPeaks(data_new30)[idx_new, c("mzmin", "mzmax")] + c(-0.02, 0.02))

plot(b, type = "XIC")
abline(h = 522.3554, col = "green", lwd = 3)
abline(h = chromPeaks(data_old30)[idx_old, c("mz")], col = "red")
abline(h = chromPeaks(data_new30)[idx_new, c("mz")], col = "blue", lty = 2)




# get maxo peak from each file. plot old and new in different colors. add theoretical


max_maxo_old <- data_old30 %>% 
                  chromPeaks() %>% 
                  as_tibble %>% 
                  group_by(sample) %>% 
                  arrange(desc(maxo)) %>% 
                  slice(1) %>% 
                  ungroup



max_maxo_new <- data_new30 %>% 
                  chromPeaks() %>% 
                  as_tibble %>% 
                  group_by(sample) %>% 
                  arrange(desc(maxo)) %>% 
                  slice(1) %>% 
                  ungroup


bind_rows(old = max_maxo_old, new = max_maxo_new, .id = "algo") %>% 
  filter(mz>522) %>%
  ggplot(aes(sample, mz, col = algo)) +
  geom_hline(yintercept =  522.3554, col = "green", size = 1) +
  geom_point(alpha = 0.5) +
  theme_bw()
  






# Orbitrap ----------------------------------------------------------------


download.file("https://www.ebi.ac.uk/metabolights/ws/studies/MTBLS469/download/4cc5d820-dc5d-4766-8112-7a05f74acef4?file=AV_01_v2_male_arm1_juice.mzXML", "AV_01_v2_male_arm1_juice.mzXML")



data_orbi <- readMSData("AV_01_v2_male_arm1_juice.mzXML", mode = "onDisk")
data_orbi <- data_orbi |>
        filterRt(c(5*60, 7.5*60)) |>
        filterMz(c(264, 266))




cwp <- CentWaveParam(peakwidth = c(2, 10), ppm = 50, integrate = 2, fitgauss= TRUE, verboseColumns = TRUE)



options(MZFUN = "getMZ")
data_old_orbi <- findChromPeaks(data_orbi, cwp)


options(MZFUN = "getWeightedMZ")
data_new_orbi <- findChromPeaks(data_orbi, cwp)




data_old_orbi %>% chromPeaks() %>% as_tibble

data_new_orbi %>% chromPeaks() %>% as_tibble


file <- 1
idx_old <- 8
idx_new <- 8



a <- data_old_orbi |>
        filterFile(file) |>
        filterRt(chromPeaks(data_old_orbi)[idx_old, c("rtmin", "rtmax")] + c(-10, -20)) |>
        filterMz(chromPeaks(data_old_orbi)[idx_old, c("mzmin", "mzmax")] + c(-0.4, 0.4))

plot(a, type = "XIC")
# abline(h = 522.3554, col = "green", lwd = 3)
abline(h = chromPeaks(data_old_orbi)[idx_old, c("mz")], col = "red", lwd=2)
abline(h = chromPeaks(data_new_orbi)[idx_new, c("mz")], col = "blue", lty = 2, lwd=2)







b <- data_new_orbi |>
filterFile(file) |>
filterRt(chromPeaks(data_new_orbi)[idx_new, c("rtmin", "rtmax")] + c(-10, -10)) |>
filterMz(chromPeaks(data_new_orbi)[idx_new, c("mzmin", "mzmax")] + c(-0.4, 0.4))

plot(b, type = "XIC")
# abline(h = 522.3554, col = "green", lwd = 3)
abline(h = chromPeaks(data_old_orbi)[idx_old, c("mz")], col = "red", lwd=2)
abline(h = chromPeaks(data_new_orbi)[idx_new, c("mz")], col = "blue", lty = 2, lwd=2)



# old algo is 40 ppm off

