# Get EICs from xcmsRaw object

Takes an `xcmsRaw` object and extracts EICs. Can do multiple ranges and
exclude certain masses unlike `getEIC`. Can be used to extract the TIC
too.

## Usage

``` r
get_EICs(
  xraw,
  range_tbl,
  exclude_mz = NULL,
  exclude_ppm = 30,
  range_tbl_cols = c("mz_lower", "mz_upper"),
  BPI = FALSE,
  min_int = 0
)
```

## Arguments

- xraw:

  `xcmsRaw` object to get EIC(s)/TIC from.

- range_tbl:

  data.frame/`tibble` with columns for the lower and upper m/z
  boundaries of EIC slice(s).

- exclude_mz:

  Masses to exclude from the EIC. Most useful to remove contaminants
  from TICs.

- exclude_ppm:

  ppm tolerance of exclude_mz

- range_tbl_cols:

  Which columns in range_tbl holds the lower and upper range. defaults
  to c("mz_lower","mz_upper").

- BPI:

  Logical selecting to calculate TIC (FALSE) or BPI.

- min_int:

  the minimum intensity mass peak to include

## Value

tbl A `tibble` containing the columns:

- **scan:** scan number

- **scan_rt:** Retention time of scan

- **intensity:** The summed intensity for each scan in the given m/z
  interval
