# Convert raw data into a tibble of xcmsRaw objects.

Convert raw data into a tibble of xcmsRaw objects.

## Usage

``` r
ic_measurements(token, boxQR, fromDate, toDate)
```

## Arguments

- token:

  A character vector containing the ICMeter token

- boxQR:

  A character vector containing QR code for the box you want to query

- fromDate:

  The starting date to draw data from

- toDate:

  The ending date to draw data to. A maximum of one month can be draw at
  a time.

## Value

data.frame holding all the data drawn
