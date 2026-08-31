# Convert raw data into a tibble of xcmsRaw objects.

Convert raw data into a tibble of xcmsRaw objects.

## Usage

``` r
xcmsRaw_to_tbl(files, ...)
```

## Arguments

- files:

  character vector of file names/paths.

- ...:

  further arguments to `xcmsRaw`.

## Value

A `tibble` containing the columns:

- **file:** Filename without path.

- **polarity:** Character string of "positive", "negative", or
  "unknown".

- **raw:** The xcmsRaw objects.

- **path:** The input path (files).
