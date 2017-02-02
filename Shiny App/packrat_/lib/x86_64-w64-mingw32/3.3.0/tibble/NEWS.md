# tibble 1.2 (2016-08-26)

## Bug fixes

- The `tibble.width` option is used for `glimpse()` only if it is finite (#153, @kwstat).
- New `as_tibble.poly()` to support conversion of a `poly` object to a tibble (#110).
- `add_row()` now correctly handles existing columns of type `list` that are not updated (#148).
- `all.equal()` doesn't throw an error anymore if one of the columns is named `na.last`, `decreasing` or `method` (#107, @BillDunlap).

## Interface changes

- New `add_column()`, analogously to `add_row()` (#99).
- `print.tbl_df()` gains `n_extra` method and will have the same interface as `trunc_mat()` from now on.
- `add_row()` and `add_column()` gain `.before` and `.after` arguments which indicate the row (by number) or column (by number or name) before or after which the new data are inserted. Updated or added columns cannot be named `.before` or `.after` (#99).
- Rename `frame_data()` to `tribble()`, stands for "transposed tibble". The former is still available as alias (#132, #143).

## Features

- `add_row()` now can add multiple rows, with recycling (#142, @jennybc).
- Use multiply character `×` instead of `x` when printing dimensions (#126). Output tests had to be disabled for this on Windows.
- Back-tick non-semantic column names on output (#131).
- Use `dttm` instead of `time` for `POSIXt` values (#133), which is now used for columns of the `difftime` class.
- Better output for 0-row results when total number of rows is unknown (e.g., for SQL data sources).

## Documentation

- New object summary vignette that shows which methods to define for custom vector classes to be used as tibble columns (#151).
- Added more examples for `print.tbl_df()`, now using data from `nycflights13` instead of `Lahman` (#121), with guidance to install `nycflights13` package if necessary (#152).
- Minor changes in vignette (#115, @helix123).


# tibble 1.1 (2016-07-01)

Follow-up release.

## Breaking changes

- `tibble()` is no longer an alias for `frame_data()` (#82).
- Remove `tbl_df()` (#57).
- `$` returns `NULL` if column not found, without partial matching. A warning is given (#109).
- `[[` returns `NULL` if column not found (#109).


## Output

- Reworked output: More concise summary (begins with hash `#` and contains more text (#95)), removed empty line, showing number of hidden rows and columns (#51). The trailing metadata also begins with hash `#` (#101). Presence of row names is indicated by a star in printed output (#72).
- Format `NA` values in character columns as `<NA>`, like `print.data.frame()` does (#69).
- The number of printed extra cols is now an option (#68, @lionel-).
- Computation of column width properly handles wide (e.g., Chinese) characters, tests still fail on Windows (#100).
- `glimpse()` shows nesting structure for lists and uses angle brackets for type (#98).
- Tibbles with `POSIXlt` columns can be printed now, the text `<POSIXlt>` is shown as placeholder to encourage usage of `POSIXct` (#86).
- `type_sum()` shows only topmost class for S3 objects.


## Error reporting

- Strict checking of integer and logical column indexes. For integers, passing a non-integer index or an out-of-bounds index raises an error. For logicals, only vectors of length 1 or `ncol` are supported. Passing a matrix or an array now raises an error in any case (#83).
- Warn if setting non-`NULL` row names (#75).
- Consistently surround variable names with single quotes in error messages.
- Use "Unknown column 'x'" as error message if column not found, like base R (#94).
- `stop()` and `warning()` are now always called with `call. = FALSE`.


## Coercion

- The `.Dim` attribute is silently stripped from columns that are 1d matrices (#84).
- Converting a tibble without row names to a regular data frame does not add explicit row names.
- `as_tibble.data.frame()` preserves attributes, and uses `as_tibble.list()` to calling overriden methods which may lead to endless recursion.


## New features

- New `has_name()` (#102).
- Prefer `tibble()` and `as_tibble()` over `data_frame()` and `as_data_frame()` in code and documentation (#82).
- New `is.tibble()` and `is_tibble()` (#79).
- New `enframe()` that converts vectors to two-column tibbles (#31, #74).
- `obj_sum()` and `type_sum()` show `"tibble"` instead of `"tbl_df"` for tibbles (#82).
- `as_tibble.data.frame()` gains `validate` argument (as in `as_tibble.list()`), if `TRUE` the input is validated.
- Implement `as_tibble.default()` (#71, hadley/dplyr#1752).
- `has_rownames()` supports arguments that are not data frames.


## Bug fixes

- Two-dimensional indexing with `[[` works (#58, #63).
- Subsetting with empty index (e.g., `x[]`) also removes row names.


# Documentation

- Document behavior of `as_tibble.tbl_df()` for subclasses (#60).
- Document and test that subsetting removes row names.


## Internal

- Don't rely on `knitr` internals for testing (#78).
- Fix compatibility with `knitr` 1.13 (#76).
- Enhance `knit_print()` tests.
- Provide default implementation for `tbl_sum.tbl_sql()` and `tbl_sum.tbl_grouped_df()` to allow `dplyr` release before a `tibble` release.
- Explicit tests for `format_v()` (#98).
- Test output for `NULL` value of `tbl_sum()`.
- Test subsetting in all variants (#62).
- Add missing test from dplyr.
- Use new `expect_output_file()` from `testthat`.


Version 1.0 (2016-03-21)
===

- Initial CRAN release

- Extracted from `dplyr` 0.4.3

- Exported functions:
    - `tbl_df()`
    - `as_data_frame()`
    - `data_frame()`, `data_frame_()`
    - `frame_data()`, `tibble()`
    - `glimpse()`
    - `trunc_mat()`, `knit_print.trunc_mat()`
    - `type_sum()`
    - New `lst()` and `lst_()` create lists in the same way that
      `data_frame()` and `data_frame_()` create data frames (hadley/dplyr#1290).
      `lst(NULL)` doesn't raise an error (#17, @jennybc), but always
      uses deparsed expression as name (even for `NULL`).
    - New `add_row()` makes it easy to add a new row to data frame
      (hadley/dplyr#1021).
    - New `rownames_to_column()` and `column_to_rownames()` (#11, @zhilongjia).
    - New `has_rownames()` and `remove_rownames()` (#44).
    - New `repair_names()` fixes missing and duplicate names (#10, #15,
      @r2evans).
    - New `is_vector_s3()`.

- Features
    - New `as_data_frame.table()` with argument `n` to control name of count
      column (#22, #23).
    - Use `tibble` prefix for options (#13, #36).
    - `glimpse()` now (invisibly) returns its argument (hadley/dplyr#1570). It
      is now a generic, the default method dispatches to `str()`
      (hadley/dplyr#1325).  The default width is obtained from the
      `tibble.width` option (#35, #56).
    - `as_data_frame()` is now an S3 generic with methods for lists (the old
      `as_data_frame()`), data frames (trivial), matrices (with efficient
      C++ implementation) (hadley/dplyr#876), and `NULL` (returns a 0-row
      0-column data frame) (#17, @jennybc).
    - Non-scalar input to `frame_data()` and `tibble()` (including lists)
      creates list-valued columns (#7). These functions return 0-row but n-col
      data frame if no data.

- Bug fixes
    - `frame_data()` properly constructs rectangular tables (hadley/dplyr#1377,
      @kevinushey).

- Minor modifications
    - Uses `setOldClass(c("tbl_df", "tbl", "data.frame"))` to help with S4
      (hadley/dplyr#969).
    - `tbl_df()` automatically generates column names (hadley/dplyr#1606).
    - `tbl_df`s gain `$` and `[[` methods that are ~5x faster than the defaults,
      never do partial matching (hadley/dplyr#1504), and throw an error if the
      variable does not exist.  `[[.tbl_df()` falls back to regular subsetting
      when used with anything other than a single string (#29).
      `base::getElement()` now works with tibbles (#9).
    - `all_equal()` allows to compare data frames ignoring row and column order,
      and optionally ignoring minor differences in type (e.g. int vs. double)
      (hadley/dplyr#821).  Used by `all.equal()` for tibbles.  (This package
      contains a pure R implementation of `all_equal()`, the `dplyr` code has
      identical behavior but is written in C++ and thus faster.)
    - The internals of `data_frame()` and `as_data_frame()` have been aligned,
      so `as_data_frame()` will now automatically recycle length-1 vectors.
      Both functions give more informative error messages if you are attempting
      to create an invalid data frame.  You can no longer create a data frame
      with duplicated names (hadley/dplyr#820).  Both functions now check that
      you don't have any `POSIXlt` columns, and tell you to use `POSIXct` if you
      do (hadley/dplyr#813).  `data_frame(NULL)` raises error "must be a 1d
      atomic vector or list".
    - `trunc_mat()` and `print.tbl_df()` are considerably faster if you have
      very wide data frames.  They will now also only list the first 100
      additional variables not already on screen - control this with the new
      `n_extra` parameter to `print()` (hadley/dplyr#1161).  The type of list
      columns is printed correctly (hadley/dplyr#1379).  The `width` argument is
      used also for 0-row or 0-column data frames (#18).
    - When used in list-columns, S4 objects only print the class name rather
      than the full class hierarchy (#33).
    - Add test that `[.tbl_df()` does not change class (#41, @jennybc).  Improve
      `[.tbl_df()` error message.

- Documentation
    - Update README, with edits (#52, @bhive01) and enhancements (#54,
      @jennybc).
    - `vignette("tibble")` describes the difference between tbl_dfs and
      regular data frames (hadley/dplyr#1468).

- Code quality
    - Test using new-style Travis-CI and AppVeyor. Full test coverage (#24,
      #53). Regression tests load known output from file (#49).
    - Renamed `obj_type()` to `obj_sum()`, improvements, better integration with
     `type_sum()`.
    - Internal cleanup.
