# Calculate EICs from a raw matrix using XCMS C function

Calculate EICs from a raw matrix of all observations (scan/mz/intensity
combinations). Can calculate for several ranges at a time

## Usage

``` r
getEIC_C_wrap(xraw_values, range_tbl)
```

## Arguments

- xraw_values:

  A data.frame/`tibble` containing the columns:

  - **scan:** scan number

  - **scan_rt:** Retention time of scan

  - **intensity:** The intensity of the observation

  - **mz:** the m/z of the observation

- range_tbl:

  data.frame/`tibble` with columns for the lower and upper
  ("mz_lower","mz_upper") m/z boundaries of EIC slice(s).

## Value

tbl A `tibble` containing the columns:

- **scan:** scan number

- **scan_rt:** Retention time of scan

- **intensity:** The summed intensity for each scan in the given m/z
  interval
