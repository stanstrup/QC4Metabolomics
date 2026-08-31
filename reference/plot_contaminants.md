# Bar plot of contaminants

Bar plot of contaminants

## Usage

``` r
plot_contaminants(
  data,
  title,
  x_var = "comp_name",
  y_var = "EIC_median",
  y_lab = "Median EIC"
)
```

## Arguments

- data:

  tbl with the contamination amounts

- title:

  Plot title

- x_var:

  Column name that holds the compound/contaminant names

- y_var:

  Column name that holds the compound/contaminant values

- y_lab:

  Y-axis label

## Value

a `ggplot` object.
