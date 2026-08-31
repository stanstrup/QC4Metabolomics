## [1.1.1](https://github.com/stanstrup/QC4Metabolomics/compare/v1.1.0...v1.1.1) (2026-08-31)


### Bug Fixes

* harden Admin module against data loss and injection ([6d7432b](https://github.com/stanstrup/QC4Metabolomics/commit/6d7432b9ec3197dd69b37f1f8a9d2cf243d71d0d))

# [1.1.0](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.12...v1.1.0) (2026-08-31)


### Bug Fixes

* override MYSQL_HOST to localhost in mariadb service to allow auto-upgrades ([973ef23](https://github.com/stanstrup/QC4Metabolomics/commit/973ef23f5bcda6ecacb4068b2e4e0b7195537aef))


### Features

* add Admin module with stats, reprocess, cleanup, and edit tools ([2afec20](https://github.com/stanstrup/QC4Metabolomics/commit/2afec204af7a2bacd6fe457b75074d5bfc0db3da))

  To enable the Admin panel add the following to your `.env` file:

  ```
  QC4METABOLOMICS_module_Admin_enabled=TRUE
  QC4METABOLOMICS_module_Admin_shiny_enabled=TRUE
  QC4METABOLOMICS_module_Admin_shiny_order=99
  QC4METABOLOMICS_module_Admin_schedule=FALSE
  QC4METABOLOMICS_module_Admin_file_schedule=FALSE
  ```
* upgrade to R 4.6.0 and Bioconductor 3.23 ([7332211](https://github.com/stanstrup/QC4Metabolomics/commit/7332211ae0388d2862e304aacecc07f4bd47b007))

## [1.0.12](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.11...v1.0.12) (2025-09-16)


### Bug Fixes

* updated R in base image. should fix package installation issues ([23f2af4](https://github.com/stanstrup/QC4Metabolomics/commit/23f2af45ee07cc6cae007012c1bdc743a0781c47))

## [1.0.11](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.10...v1.0.11) (2025-09-16)


### Bug Fixes

* properly update bioconductor version. ([1f8a788](https://github.com/stanstrup/QC4Metabolomics/commit/1f8a7886ff29a95f96ff05f70f200f0961a05bad))

## [1.0.10](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.9...v1.0.10) (2025-09-16)


### Bug Fixes

* updated mzR (and many other packages) + R to support new orbitrap: ([ba280c7](https://github.com/stanstrup/QC4Metabolomics/commit/ba280c73730818e956eb90ac506550b57f4c6f02))

## [1.0.9](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.8...v1.0.9) (2025-08-18)


### Bug Fixes

* converter that handles ([fc10e8c](https://github.com/stanstrup/QC4Metabolomics/commit/fc10e8cfc7e158c02f7434497db735d5d7fba604))

## [1.0.8](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.7...v1.0.8) (2025-07-30)


### Bug Fixes

* made all shiny models do a self-test to check that they are initialized before running any code. ([69b0a5c](https://github.com/stanstrup/QC4Metabolomics/commit/69b0a5c8dccc0a918d16c3f6eebb9b83319781a4))
* now checks individually for each relevant module if there are new files to schedule. Previously only files with no previous schedules could be scheduled. This caused newly enabled modules to have no effect. ([914d38a](https://github.com/stanstrup/QC4Metabolomics/commit/914d38ae911f13940153bb4040b4241231c74f6b))

## [1.0.7](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.6...v1.0.7) (2025-07-30)


### Bug Fixes

* drop the idea of the dynamic name since we cannot infer the filename of the latest version then. ([0dfae00](https://github.com/stanstrup/QC4Metabolomics/commit/0dfae005621fab9b38aabdf76b4b19bf3210c0c6))
* forgot input path to zip ([25223f9](https://github.com/stanstrup/QC4Metabolomics/commit/25223f980c35d51e10d9b2e4c7d7c23d18c13d30))

## [1.0.7](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.6...v1.0.7) (2025-07-30)


### Bug Fixes

* drop the idea of the dynamic name since we cannot infer the filename of the latest version then. ([0dfae00](https://github.com/stanstrup/QC4Metabolomics/commit/0dfae005621fab9b38aabdf76b4b19bf3210c0c6))

## [1.0.6](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.5...v1.0.6) (2025-07-30)


### Bug Fixes

* use the name attribute to set the file name with version ([c477884](https://github.com/stanstrup/QC4Metabolomics/commit/c477884fc6cb7ebbb6db0e7a9d7f70435cd139c1))

## [1.0.5](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.4...v1.0.5) (2025-07-30)


### Bug Fixes

* trigger release ([cc8f5a9](https://github.com/stanstrup/QC4Metabolomics/commit/cc8f5a9d461a78b8cc3a07602588342a4a85ac57))

## [1.0.4](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.3...v1.0.4) (2025-07-29)


### Bug Fixes

* better naming ([73e779f](https://github.com/stanstrup/QC4Metabolomics/commit/73e779f10962a9c2c32c8ba6f1997b8b82626f55))

## [1.0.3](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.2...v1.0.3) (2025-07-29)


### Bug Fixes

* update filename of release ([f91398d](https://github.com/stanstrup/QC4Metabolomics/commit/f91398d0d831ec34864012564f27e3cb6f40cc11))

## [1.0.2](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.1...v1.0.2) (2025-07-29)


### Bug Fixes

* LFS files in release ([94ad556](https://github.com/stanstrup/QC4Metabolomics/commit/94ad5565096e3c067a8b37b970564f6a52a3b5a9))

## [1.0.1](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.0...v1.0.1) (2025-07-29)


### Bug Fixes

* more ignore ([bc94485](https://github.com/stanstrup/QC4Metabolomics/commit/bc94485b53d89c2a3b02e6b8cde8042e57d3c343))
* trigger release ([279d33e](https://github.com/stanstrup/QC4Metabolomics/commit/279d33ea8d7909d212b0a905c645e8fe4205a8bb))

## [1.0.1](https://github.com/stanstrup/QC4Metabolomics/compare/v1.0.0...v1.0.1) (2025-07-29)


### Bug Fixes

* trigger release ([279d33e](https://github.com/stanstrup/QC4Metabolomics/commit/279d33ea8d7909d212b0a905c645e8fe4205a8bb))

# 1.0.0 (2025-07-29)


### Bug Fixes

* one complete workflow ([d441874](https://github.com/stanstrup/QC4Metabolomics/commit/d441874e737cd8d51ff8b384c459cc6acc5a36fc))


### Features

* add release and semantic release ([c869a78](https://github.com/stanstrup/QC4Metabolomics/commit/c869a788b240eb5d18844c42933e3a2f22861f71))
