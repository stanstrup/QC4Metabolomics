library(dplyr)

folders <- c(c(#"I:/SCIENCE-NEXS-NyMetabolomics/Projects/Xiaotian/Xiaotian.pro/mzML",
               #"I:/SCIENCE-NEXS-NyMetabolomics/Projects/DAminoAcids/DAminoAcids.pro/mzML",
               #"I:/SCIENCE-NEXS-NyMetabolomics/Projects/PRIMA projects"
               "I:/SCIENCE-NEXS-NyMetabolomics/Projects/PRIMA projects/PRIMA.pro/PRIMA urin metabolomics/pos_mode"
             ))


# folders <- list.dirs("I:/SCIENCE-NEXS-NyMetabolomics/Projects/",recursive = FALSE) %>% 
#             {tibble(dir = ., file.info(.))} %>% 
#             arrange(desc(ctime)) %>% 
#             slice(1:10) %>% 
#             pull(dir)



folders <- 
c(
"/data/5410.PRO", 
"/data/AD-LEO project Madura/humanserum.pro",
"/data/Anna Sofie Husted/Anna.pro", 
"/data/Banana_Party_urine.pro",
"/data/BEST.pro/02082012", 
"/data/BEST.pro/23072012", 
"/data/Bone and teeth/Andreas/Andreas",
"/data/Bone and teeth/Andreas/Andrew pig samples", 
"/data/Bone and teeth/Andreas/Mouse september 14",
"/data/Bone and teeth/Anna Fotakis (teeht samples)", 
"/data/Bone and teeth/Bone metabolites.pro",
"/data/Cancer studies",
"/data/Cancer studies",
"/data/Chicken breast",
"/data/Coffee", 
"/data/CWS WP1 PCOS urine.pro", 
"/data/DAminoAcids/D-AminoAcids2.pro",
"/data/Dan fecal sample", 
"/data/DanORC studies",
"/data/Dried blood spots",
"/data/Drill fecal samples.pro",
"/data/EnergyDrinkOrangeJuice",
"/data/Famus/FamusSCFA2400/Fecal extration test Sandra.pro",
"/data/Fruit and vegetables studies",
"/data/Giorgia.pro", 
"/data/HE-specialer (Pia)/Cannabioler_speciale_stud_project.pro",
"/data/Ion suppression (Thaer)",
"/data/KCROS2008 (anna)",
"/data/Liver samples with.pro",
"/data/M208 Havtorn.pro",
"/data/M210 MEDA study 2014",
"/data/M212 Metabeer",
"/data/M226 Barley/Serum.pro",
"/data/M226 Barley/Urine.pro",
"/data/Mark Hvistendahl RH Stoma fecal samples",
"/data/Methods/Anticoagulant exp_150611_pos.pro",
"/data/Methods/Anticoagulant exp_160611_neg.pro",
"/data/Methods/Auto_ID_Halle", 
"/data/Methods/Protein precipitation/Protein experiment_neg_NEW LONG LC-MS METHOD.PRO",
"/data/Methods/Protein precipitation/Protein experiment_pos_NEW LONG LC-MS METHOD.PRO",
"/data/Methods/Protein precipitation/Protein experiment_pos_OLD LC-MS METHOD.PRO",
"/data/Mouse samples/Aarhus knockout mice 2013.pro", 
"/data/Mouse samples/Aarhus knockout mice 2014.pro",
"/data/Mouse samples/Liver samples 190514", 
"/data/Nati studies/Natalia Dietary portfolio.pro/Natalia Dietary portfolio serum plate 1",
"/data/Nati studies/Natalia Dietary portfolio.pro/Natalia Dietary portfolio serum plate 2",
"/data/Nati studies/Nati study.pro/Natalia latest", 
"/data/Nati studies/Nati study.pro/Natalia MSMS oct. 2016",
"/data/Nati studies/Nati study.pro/Natalia_plasma_first_run",
"/data/Nati studies/Nati study.pro/Natalia_Portfolio_run",
"/data/Nati studies/Nati study.pro/Nati Msms",
"/data/NoMa/RCT/Plate 2 redo new column.pro",
"/data/NoMa/RCT/Plate 2 redo.pro",
"/data/NoMa/RCT/Plate1.pro", 
"/data/NoMa/RCT/Plate2", 
"/data/NoMa/RCT/Plate3.pro",
"/data/NoMa/SCR/Plate1.pro", 
"/data/NoMa/SCR/Plate2.pro", 
"/data/NoMa/SCR/Plate3.pro",
"/data/OPUS studies",
"/data/Selenium studies", 
"/data/SPICES-Linn.pro", 
"/data/Standards/Bile Acids standards_MSE.pro",
"/data/Standards/Column tests+Coffee+standards", 
"/data/SYSDIET",
"/data/PRIMA projects/PRIMA.pro/PRIMA urin metabolomics/pos_mode"

) %>% 
  gsub("/data/","I:/SCIENCE-NEXS-NyMetabolomics/Projects/", .)








out_file <- "I:/SCIENCE-NEXS-NyMetabolomics/Projects/mzML_filelist.txt"


# files <- list.files(folders, "\\.mzML$", full.names = TRUE)
files <- list.files(folders, "\\.mzML$", full.names = TRUE, recursive = TRUE)


files <- gsub("I:/SCIENCE-NEXS-NyMetabolomics/Projects/", "/data/", files)

# read existing list
old_files <- readLines(out_file)

# remove all-ready found files
files <- files[!(files %in% old_files)]


# write out list with new files
if(length(files)!=0) cat(files, file = out_file, sep="\n", append=TRUE)



# Alternatively to rewrite list with only working links -------------------
files_all <- unique(c(files, old_files))
files_all <- files_all %>% 
            gsub("/data/","I:/SCIENCE-NEXS-NyMetabolomics/Projects/", .) %>% 
            {files_all[file.exists(.)]}

# write out list
if(length(files_all)!=0) writeLines(files_all, out_file)











# remove dead flies -------------------------------------------------------
out_file <- "/data/mzML_filelist.txt"
old_files <- readLines(out_file)
file_exists <- file.exists(old_files)

str(old_files)
str(old_files[file_exists])

writeLines(old_files[file_exists], out_file)

# does all contain mzML in path?
grep("mzML/",old_files[file_exists], fixed = TRUE, invert = TRUE, value = TRUE)




# re-write file with normalized links -------------------------------------
out_file <- "/data/mzML_filelist.txt"
old_files <- readLines(out_file)

file_exists <- file.exists(old_files)
old_files <- old_files[file_exists]


 #normalizePath()
