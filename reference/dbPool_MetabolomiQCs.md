# Write message to QC4Metabolomics db

Write message to QC4Metabolomics db

## Usage

``` r
dbPool_MetabolomiQCs(idleTimeout = 1)
```

## Arguments

- idleTimeout:

  The number of minutes that an idle object will be kept in the pool
  before it is destroyed.

## Value

A `dbPool` object to connect to the MetabolomiQC database using settings
in the ini file.
