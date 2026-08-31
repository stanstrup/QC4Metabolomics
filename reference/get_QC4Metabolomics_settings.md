# Get table with QC4metabolomics settings

Get table with QC4metabolomics settings

## Usage

``` r
get_QC4Metabolomics_settings(modules = NULL)
```

## Arguments

- modules:

  character strong. Get settings only for selected modules.

## Value

tbl A `tibble` containing the columns:

- **name:** name of the setting

- **value:** value of the settin

- **module:** which module the setting belongs to.
