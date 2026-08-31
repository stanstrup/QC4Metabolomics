# Extract polarity from xcmsRaw object.

Extracts polarity from an xcmsRaw object. The polarity found in the
majority of scans is returned.

## Usage

``` r
extract_polarity(xraw)
```

## Arguments

- xraw:

  The xcmsRaw object to extract polarity from.

## Value

A character string giving the polarity. Can be "positive", "negative",
or "unknown".
