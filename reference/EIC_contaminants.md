# Find EICs that behave like contaminants

This function looks in raw LC-MS data for "features"/EICs that behave
like contaminants. Behaving like contaminants in this case means that a
certain m/z values is present in more than `min_time` above intensity
`min_int`.

## Usage

``` r
EIC_contaminants(
  raw,
  bin_ppm = 30,
  interval_ppm = 30,
  min_time = 5,
  merge_corr = 0.9,
  merge_ppm = 30,
  min_int = 5000
)
```

## Arguments

- raw:

  `xcmsRaw` object to profile

- bin_ppm:

  Tolerance (ppm) for initial binning of m/z values

- interval_ppm:

  Tolerance for creating final EICs after merging similar bins

- min_time:

  Minimum time (minutes) an EIC should be above `min_int` to be
  considered a contaminant.

- merge_corr:

  Minimum correlation between EICs to be merged.

- merge_ppm:

  Maximum difference (ppm) between EICs to be merged.

- min_int:

  Minimum intensity that the EIC needs to be above for a a minimum of
  `min_time`.

## Value

A `tibble` containing the columns:

- **mz:** m/z of the proposed contaminant

- **EIC:** EIC of the m/z.
