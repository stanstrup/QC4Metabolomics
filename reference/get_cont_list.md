# Get list of known contaminants

Get list of known contaminants

## Usage

``` r
get_cont_list(polarity = c("positive", "negative", "unknown"), type = "URL")
```

## Arguments

- polarity:

  The polarity to get contaminants for. Can be "positive", "negative" or
  "unknown". If "unknown" the list specified in the MetabolomiQCs.conf
  is used. MetabolomiQCs.conf can be in the working folder or the home
  folder. If those are not found the package default is used (unknown
  will used the positive mode list).

- type:

  If using local or remote. Only "URL" implemented which downloads a
  list from https://github.com/stanstrup/common_mz

## Value

tbl A `tibble` containing the columns:

- **Monoisotopic ion mass (singly charged):** m/z of the contaminant

- **Ion type:** Notation for adduct/fragment type

- **Formula for M or subunit or sequence:** Molecular formula

- **Compound ID or species:** Name of the compound

- **Possible origin and other comments:** Suggestion for the origin of
  the contaminant

- **References:** Reference for the contaminant

## References

https://github.com/stanstrup/common_mz
