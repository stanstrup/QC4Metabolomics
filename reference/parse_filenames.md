# Parse filenames from given string

Parse filenames from given string

## Usage

``` r
parse_filenames(filenames, filenamemask)
```

## Arguments

- filenames:

  Character string with the filenames to parse.

- filenamemask:

  Filename mask. Variables to capture are inclosed by "%". See examples

## Value

data.frame with fields parsed from the filenames

## Author

Stinus Lindgreen, <sldg@steno.dk>; Jan Stanstrup, <jpzs@steno.dk>

## Examples

``` r
testfilenames <- c("RemoveThis_METSY_sample1___17-random_AndThis.txt",
                   "RemoveThis_METSY_sample2___21-something_AndThis.txt",
                   "RemoveThis_METSY_sample3___123-blah_AndThis.txt",
                   "RemoveThis_JDRF_SameName___1-dummyA_AndThis.txt",
                   "RemoveThis_JDRF_SameName___2-dummyB_AndThis.txt",
                   "RemoveThis_JDRF_SameName___3-dummyC_AndThis.txt",
                   "RemoveThis_this_file___name-is_wrong",
                   "RemoveThis_and_this_AndThis.txt",
                   "RemoveThis_this_one___should-work",
                   "RemoveThis_how_about___this_-_one_AndThis.txt"
                  )

defaultmask   <- "RemoveThis_%study%_%name%___%rep%-%dummy%_AndThis.txt"

parse_filenames(testfilenames,defaultmask)
#>                                               filename study     name   rep
#> 1     RemoveThis_METSY_sample1___17-random_AndThis.txt METSY  sample1    17
#> 2  RemoveThis_METSY_sample2___21-something_AndThis.txt METSY  sample2    21
#> 3      RemoveThis_METSY_sample3___123-blah_AndThis.txt METSY  sample3   123
#> 4      RemoveThis_JDRF_SameName___1-dummyA_AndThis.txt  JDRF SameName     1
#> 5      RemoveThis_JDRF_SameName___2-dummyB_AndThis.txt  JDRF SameName     2
#> 6      RemoveThis_JDRF_SameName___3-dummyC_AndThis.txt  JDRF SameName     3
#> 7                 RemoveThis_this_file___name-is_wrong  <NA>     <NA>  <NA>
#> 8                      RemoveThis_and_this_AndThis.txt  <NA>     <NA>  <NA>
#> 9                    RemoveThis_this_one___should-work  <NA>     <NA>  <NA>
#> 10       RemoveThis_how_about___this_-_one_AndThis.txt   how    about this_
#>        dummy  FLAG
#> 1     random FALSE
#> 2  something FALSE
#> 3       blah FALSE
#> 4     dummyA FALSE
#> 5     dummyB FALSE
#> 6     dummyC FALSE
#> 7       <NA>  TRUE
#> 8       <NA>  TRUE
#> 9       <NA>  TRUE
#> 10      _one FALSE

```
