# Calculate EIC from a raw matrix

Calculate EIC from a raw matrix of all observations (scan/mz/intensity
combinations).

## Usage

``` r
EIC_calc(tbl, lower, upper, BPI = FALSE)
```

## Arguments

- tbl:

  A `tibble` containing the columns:

  - **scan:** scan number

  - **scan_rt:** Retention time of scan

  - **intensity:** The intensity of the observation

  - **mz:** the mz of the observation

- lower:

  Lower boundary of EIC slice

- upper:

  Upper boundary of EIC slice

- BPI:

  Logical selecting to calculate TIC (FALSE) or BPI.

## Value

tbl A `tibble` containing the columns:

- **scan:** scan number

- **scan_rt:** Retention time of scan

- **intensity:** The summed intensity for each scan in the given m/z
  interval
