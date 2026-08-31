# Remove files that no longer exist from the database

Remove files that no longer exist from the database

## Usage

``` r
rem_dead_files(file_md5, path, pool = NULL, log_source)
```

## Arguments

- file_md5:

  A vector giving the md5 of the files to check.

- path:

  A vector giving the relative path to the files to check.

- pool:

  (see pool package) to use for writing. If null a new connection will
  be made reading the connection details from the conf file.

## Value

Database change and a logical vector saying which files existed.
