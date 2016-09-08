#' Parse filenames from given string
#'
#' @param filenames Character string with the filenames to parse.
#' @param filenamemask Filename mask. Variables to capture are inclosed by "\%". See examples
#'
#' @return data.frame with fields parsed from the filenames
#' @export
#'
#' @author Stinus Lindgreen, \email{sldg@@steno.dk}; Jan Stanstrup, \email{jpzs@@steno.dk}
#'
#' @importFrom stringr str_match
#' 
#' @examples
#' testfilenames <- c("RemoveThis_METSY_sample1___17-random_AndThis.txt",
#'                    "RemoveThis_METSY_sample2___21-something_AndThis.txt",
#'                    "RemoveThis_METSY_sample3___123-blah_AndThis.txt",
#'                    "RemoveThis_JDRF_SameName___1-dummyA_AndThis.txt",
#'                    "RemoveThis_JDRF_SameName___2-dummyB_AndThis.txt",
#'                    "RemoveThis_JDRF_SameName___3-dummyC_AndThis.txt",
#'                    "RemoveThis_this_file___name-is_wrong",
#'                    "RemoveThis_and_this_AndThis.txt",
#'                    "RemoveThis_this_one___should-work",
#'                    "RemoveThis_how_about___this_-_one_AndThis.txt"
#'                   )
#' 
#' defaultmask   <- "RemoveThis_%study%_%name%___%rep%-%dummy%_AndThis.txt"
#' 
#' parse_filenames(testfilenames,defaultmask)
#' 
#' 

parse_filenames <- function(filenames,filenamemask){

    
    # We find what goes before first field we want and what comes after (searching for first and last %)
	trim_preseq  <- sub("%.*$", "" , filenamemask)
	trim_postseq <- sub("^.*%", "" , filenamemask)

	# remove pre and post strings from mask so we only have the fields and separators
	sep_locs <- unlist(gregexpr(pattern ='%', filenamemask))
	mask     <- substr(filenamemask, min(sep_locs)+1, max(sep_locs)-1)
	fields   <- unlist(strsplit(mask,split="%"))
	
	# get field names and separators separately
	field_names <- fields[  seq.int(1, length(fields), 2)  ]
	field_seps  <- fields[  seq.int(2, length(fields), 2)  ]
	
	# build regular expression for extraction
	search_reg <- c(trim_preseq, field_seps, trim_postseq)
	search_reg <- paste(search_reg, collapse ="(.*)")
	
	# match string with pattern
	out_table <- str_match(filenames,search_reg)
	
	# make data.frame
	out_table <- as.data.frame(out_table, stringsAsFactors = FALSE)
	
	# flag if something seems to have gone wrong
	FLAG <- rowSums(is.na(out_table)) > 0
	
	# clean up table
	out_table <- out_table[,-1] # remove complete match
	out_table <- cbind.data.frame(filenames,out_table, FLAG, stringsAsFactors = FALSE) # add the filenames and flags
	colnames(out_table) <- c("filename", field_names, "FLAG") # column names
	

	return(out_table)
	
}

