# Calculate Tailing Factor and Asymmetry Factor

Calculate Tailing Factor and Asymmetry Factor

## Usage

``` r
peak_factor(EIC, rt, factor = "TF")
```

## Arguments

- EIC:

  EIC containing the peak to calculate for. `tibble` as produced with
  [`get_EICs`](https://github.com/stanstrup/QC4Metabolomics/reference/get_EICs.md).

- rt:

  Retention time of the center of the peak (Numeric)

- factor:

  to calculate. Character string either "TF" (Tailing Factor) or "ASF"
  (Asymmetry Factor).

## Value

Numeric

## References

http://www.chromforum.org/viewtopic.php?t=20079
