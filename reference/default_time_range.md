# Remove files that no longer exist from the database

Return is a giving the dates corresponding to the last min_samples
number of samples, but at least ALL samples from the last min_weeks
weeks.

## Usage

``` r
default_time_range(min_weeks = 2, min_samples = 200, pool = NULL)
```

## Arguments

- min_weeks:

  A vector saying the minimum number of weeks to return samples from.

- min_samples:

  A vector saying how many samples to minimum return. Always returns all
  samples from min_weeks period.

- pool:

  (see pool package) to use for writing. If null a new connection will
  be made reading the connection details from the conf file.

## Value

Named vector (min, max) with POSIXct times.
