library(purrr)
library(glue)

# Set UTF-8 locale (works in Docker)
Sys.setenv(LC_ALL = "C.UTF-8", LANG = "C.UTF-8")

basedir <- "/data"
temp_workdir <- file.path(basedir, ".temp_conversion")
input_exts <- trimws(strsplit(Sys.getenv("QC4METABOLOMICS_msconvert_input_ext", ".raw"), ";")[[1]])
input_ext_regex <- paste0("(", paste0("\\", input_exts, collapse = "|"), ")$")

get_input_ext <- function(filename) {
  for (ext in input_exts) {
    if (grepl(paste0("\\", ext, "$"), filename, ignore.case = TRUE)) return(ext)
  }
  input_exts[1]
}

# Conversion function with smart ASCII/Unicode handling
convert_file <- function(i, files, files_out, outdir, basedir, temp_workdir) {
  temp_input_file <- NULL
  expected_temp_output <- NULL
  used_copy_method <- FALSE
  
  tryCatch({
    # Check if filename contains non-ASCII characters
    filename <- basename(files[i])
    has_non_ascii <- any(utf8ToInt(filename) > 127)
    
    if (has_non_ascii) {
      message("Converting (copy method): ", filename, " [contains non-ASCII chars]")
      
      # Create temporary copy with ASCII-safe name for input
      timestamp <- format(Sys.time(), '%Y%m%d_%H%M%S_%OS3')
      file_ext <- get_input_ext(filename)
      safe_input_name <- glue("temp_input_{i}_{timestamp}{file_ext}")
      temp_input_file <- file.path(temp_workdir, safe_input_name)
      
      if (!file.copy(files[i], temp_workdir, recursive = TRUE)) {
        stop("Failed to copy input file/directory")
      }

      copied_dir <- file.path(temp_workdir, basename(files[i]))
      if (!file.rename(copied_dir, temp_input_file)) {
        stop("Failed to rename copied file/directory")
      }
      
      used_copy_method <- TRUE
      input_path <- temp_input_file
      output_dir <- temp_workdir
      
    } else {
      message("Converting (direct method): ", filename, " [ASCII-safe]")
      
      # Use file directly - no copy needed
      used_copy_method <- FALSE
      input_path <- files[i]
      output_dir <- outdir[i]
      
      # Ensure output directory exists for direct method
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    
    # Get msconvert arguments and build command
    msconvert_args <- gsub("\\\\", "", Sys.getenv("QC4METABOLOMICS_msconvert_args"))
    cmd <- glue('wine msconvert "{input_path}" {msconvert_args} --outdir "{output_dir}"')
    
    result <- system(cmd, intern = FALSE)
    
    if (result != 0) {
      message("msconvert failed for: ", basename(files[i]), " (exit code: ", result, ")")
      return("FAILED TO CONVERT")
    }
    
    if (used_copy_method) {
      # Handle temp file method - need to rename output
      expected_temp_output <- file.path(temp_workdir, gsub(input_ext_regex, ".mzML", basename(temp_input_file)))
      
      if (!file.exists(expected_temp_output)) {
        message("Expected temp output file not found for: ", basename(files[i]))
        message("Expected: ", expected_temp_output)
        return("FAILED TO CONVERT")
      }
      
      # Ensure final output directory exists
      dir.create(dirname(files_out[i]), recursive = TRUE, showWarnings = FALSE)
      
      # Rename temp file to final UTF-8 location
      if (!file.rename(expected_temp_output, files_out[i])) {
        message("Failed to rename temp output to final location for: ", basename(files[i]))
        return("FAILED TO CONVERT")
      }
      
      # Verify the rename worked
      if (!file.exists(files_out[i]) || file.exists(expected_temp_output)) {
        message("Rename verification failed for: ", basename(files[i]))
        return("FAILED TO CONVERT")
      }
    } else {
      # Direct method - output should already be in correct location
      if (!file.exists(files_out[i])) {
        message("Expected output file not found for: ", basename(files[i]))
        message("Expected: ", files_out[i])
        return("FAILED TO CONVERT")
      }
    }
    
    # Add to filelist and report success (deduplicate; use sep="" to avoid trailing space)
    filelist_path <- glue("{basedir}/mzML_filelist.txt")
    existing <- if (file.exists(filelist_path)) trimws(readLines(filelist_path, warn = FALSE)) else character(0)
    if (!normalizePath(files_out[i], mustWork = FALSE) %in% normalizePath(existing, mustWork = FALSE)) {
        cat(paste0(files_out[i], "\n"), file = filelist_path, append = TRUE)
    }
    message("Successfully converted: ", basename(files[i]))
    return("SUCCESS")
    
  }, error = function(e) {
    message("Error converting ", basename(files[i]), ": ", e$message)
    return("FAILED TO CONVERT")
  }, finally = {
    # Cleanup: only remove temp files if we used the copy method
    if (used_copy_method) {
      if (!is.null(temp_input_file) && dir.exists(temp_input_file)) {
        unlink(temp_input_file, recursive = TRUE)
      }
      if (!is.null(expected_temp_output) && file.exists(expected_temp_output)) {
        file.remove(expected_temp_output)
      }
    }
  })
}

# Main conversion process
message("Starting conversion at: ", Sys.time())

# Get file list either from txt file or by scanning recursively
files_from_txt <- as.logical(Sys.getenv("QC4METABOLOMICS_msconvert_files_from_txt", "TRUE"))

if (files_from_txt) {
  message("Reading file list from raw_filelist.txt")
  files <- readLines(glue("{basedir}/raw_filelist.txt"), encoding = "UTF-8")
  files <- glue("{basedir}/{files}")
  files <- gsub("\"", "", files)
  files <- gsub("\\\\", "/", files)
  files <- trimws(files)

  files <- iconv(files, from = "UTF-8", to = "UTF-8", sub = "")
  Encoding(files) <- "UTF-8"
} else {
  message("Scanning recursively for files matching: ", paste(input_exts, collapse = ", "))
  files <- list.files(path = basedir, pattern = input_ext_regex,
                      recursive = TRUE, full.names = TRUE, include.dirs = TRUE)
  files <- files[!grepl("/.temp_conversion/", files, fixed = TRUE)]

  exclude_path <- trimws(Sys.getenv("QC4METABOLOMICS_msconvert_exclude_path", ""))
  if (nchar(exclude_path) > 0) {
    exclude_pat <- paste(trimws(strsplit(exclude_path, ";")[[1]]), collapse = "|")
    files <- files[!grepl(exclude_pat, files)]
  }
}

if(length(files) > 0) {
  message("Sample file: ", files[1])
}

# Remove files that don't exist (anymore)
file_exist <- file.exists(files)
files <- files[file_exist]
outdir <- glue("{dirname(files)}{Sys.getenv('QC4METABOLOMICS_msconvert_outdir_prefix')}")

# Remove files that have already been converted
files_b <- basename(files)
files_out <- glue("{outdir}/{gsub(input_ext_regex, '', files_b)}.mzML")
file_exist <- file.exists(files_out)
files <- files[!file_exist]
outdir <- outdir[!file_exist]
files_out <- files_out[!file_exist]

# Early exit if no new files to convert
if(length(files) == 0) {
  message("No new files to convert")
  message("Conversion completed at: ", Sys.time())
  quit(status = 0)
}

# Setup temporary working directory
dir.create(temp_workdir, recursive = TRUE, showWarnings = FALSE)

# Ensure cleanup of temp directory on script exit
on.exit({
  if (dir.exists(temp_workdir)) {
    unlink(temp_workdir, recursive = TRUE)
  }
})

# Create output directories
walk(unique(outdir), ~ dir.create(.x, recursive = TRUE, showWarnings = FALSE))

# Convert all files using purrr::map
results <- map_chr(seq_along(files), ~ convert_file(.x, files, files_out, outdir, basedir, temp_workdir))

# Report results
success_count <- sum(results == "SUCCESS")
message(glue("Successfully converted {success_count} out of {length(files)} files"))

message("Conversion completed at: ", Sys.time())
