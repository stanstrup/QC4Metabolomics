# Match list of standards to peak table

This function will match a table of standard compounds and a peak table
by m/z and retention time. If there is more than one possible hit the
highest intensity peak will be chosen.

## Usage

``` r
closest_match(
  stds,
  peakTable,
  rt_tol = 0.25,
  mz_ppm = 30,
  rt_col = "rt",
  mz_col = "mz",
  int_col = "into"
)
```

## Arguments

- stds:

  `tibble` of standards to match to a peak table

- peakTable:

  `tibble` containing peak table supplied by `findPeaks` (but converted
  to `tibble`/[`data.frame`](https://rdrr.io/r/base/data.frame.html)).

- rt_tol:

  Retention time tolerance for matching peaks. Pay attention to the unit
  of your tables. rt_tol should match and stds and peakTable should use
  same units (i.e. minutes of seconds).

- mz_ppm:

  ppm for matching peaks.

- rt_col:

  Character string giving the column containing the retention times.
  Must be same in standards and peak table.

- mz_col:

  Character string giving the column containing the m/z values. Must be
  same in standards and peak table.

- int_col:

  Character string giving the column containing the intensities in the
  peak table.

## Value

A vector having the length equivalent to the number of rows in stds
giving the indices of the hits in peakTable.
