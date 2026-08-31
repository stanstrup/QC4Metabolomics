# Convert a list of peaks (rt / m/z pairs) to a Region of Interest (ROI) list for use with `findPeaks`

Convert a list of peaks (rt / m/z pairs) to a Region of Interest (ROI)
list for use with `findPeaks`

## Usage

``` r
tbl2ROI(tbl, raw, ppm, rt_tol)
```

## Arguments

- tbl:

  `tibble` containing the columns "rt" and "mz". rt needs to be in
  seconds.

- raw:

  `xcmsRaw` object to create ROI for. It needs to be a specific
  `xcmsRaw` to match retention times to scan nubmers.

- ppm:

  ppm tolerance for the generated ROI.

- rt_tol:

  Retention time tolerance (in sec!) for the generated ROI.

## Value

List containing the ROIs. Each list contains mz, mzmin, mzmax, scmin,
scmax, length (set to -1, not used by centWave) and intensity (set to
-1, not used by centWave) columns.
