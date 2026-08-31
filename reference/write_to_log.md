# Write message to QC4Metabolomics db

Write message to QC4Metabolomics db

## Usage

``` r
write_to_log(msg, cat, source, pool = NULL)
```

## Arguments

- msg:

  The message. A character vector.

- cat:

  The category ("info", "warning" or "error"). A character vector.

- pool:

  (see pool package) to use for writing. If null a new connection will
  be made reading the connection details from the conf file.

## Value

Nothing. Written to db.
