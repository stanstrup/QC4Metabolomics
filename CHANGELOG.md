## [1.1.7](https://github.com/stanstrup/QC4Metabolomics/compare/v1.1.6...v1.1.7) (2026-08-31)


### Bug Fixes

* correct renv library glob depth and drop redundant pkgdown install ([16a3570](https://github.com/stanstrup/QC4Metabolomics/commit/16a3570aedf5e17d85f51a97714af49ccc1b819b))

## [1.1.6](https://github.com/stanstrup/QC4Metabolomics/compare/v1.1.5...v1.1.6) (2026-08-31)


### Bug Fixes

* use R_LIBS to expose base image renv library instead of renv::load() ([f772799](https://github.com/stanstrup/QC4Metabolomics/commit/f772799ff5afd74a9a090617368e242dd3aecab8))

## [1.1.5](https://github.com/stanstrup/QC4Metabolomics/compare/v1.1.4...v1.1.5) (2026-08-31)


### Bug Fixes

* apt-get update before installing pandoc and rsync in pkgdown job ([24c5a79](https://github.com/stanstrup/QC4Metabolomics/commit/24c5a797b74f136fcdc2a947434ab5e1813f2a6b))

## [1.1.4](https://github.com/stanstrup/QC4Metabolomics/compare/v1.1.3...v1.1.4) (2026-08-31)


### Bug Fixes

* guard against empty IN () when global_instruments_input() is empty at startup ([3cc856e](https://github.com/stanstrup/QC4Metabolomics/commit/3cc856e72bbef69eb72dffff1baa5581e898fe82))
* guard all IN () clauses built from UI inputs that may be NULL at startup ([4502ac0](https://github.com/stanstrup/QC4Metabolomics/commit/4502ac0ae965c62872922d2960ec639e311d3ba4))

## [1.1.3](https://github.com/stanstrup/QC4Metabolomics/compare/v1.1.2...v1.1.3) (2026-08-31)


### Bug Fixes

* add 60s timeout to GET calls in get_cont_list (M10) ([eea12a0](https://github.com/stanstrup/QC4Metabolomics/commit/eea12a0d99023338559dd60b05a1db3698c64927))
* add libuv1-dev for fs/pkgdown build and bump checkout to v7 ([4381f01](https://github.com/stanstrup/QC4Metabolomics/commit/4381f0124bea3e204280e98f44ac643cc33565d4))
* C1 scope Warner UPDATE to captured pending md5s; C2 make FileInfo ignore-list writes atomic ([6c04592](https://github.com/stanstrup/QC4Metabolomics/commit/6c04592816daad52bd998d014a2c23fdf0957a71))
* email header group count must match 9 SELECT columns not 12 (M5) ([96a670c](https://github.com/stanstrup/QC4Metabolomics/commit/96a670c14fe90cee305ba699aabaaf9d61da79cb))
* move ICMeter access_token from URL to Authorization header (H12) ([99ade63](https://github.com/stanstrup/QC4Metabolomics/commit/99ade63cdebedd9d724d8dd138c6ed249dc64b8d))
* on.exit guards, atomic transactions, pivot_longer, VALUES alias, remove debug print (M1/M2/L1/L6 TrackCmp) ([ae56d2e](https://github.com/stanstrup/QC4Metabolomics/commit/ae56d2ee532a44a530a506a83e29a016b71da8ea))
* on.exit guards, atomic transactions, VALUES alias, wrong error log var, pivot_longer (M1/M2/M3/L6 Contaminants) ([42f505e](https://github.com/stanstrup/QC4Metabolomics/commit/42f505e16bc095add9ea50ec8ed1b70d07505203))
* prevent SQL injection in TrackCmp compound edit/delete (H1) ([2320088](https://github.com/stanstrup/QC4Metabolomics/commit/2320088c7c406cfbd8882e6b9a52215f91f85e4a))
* prevent SQL injection in TrackCmp stats query (H4) ([9889142](https://github.com/stanstrup/QC4Metabolomics/commit/988914244a5edee343600c6393bd605b6bdcfc99))
* prevent SQL injection in Warner get_data_matching_rules (H3) ([fcff9e4](https://github.com/stanstrup/QC4Metabolomics/commit/fcff9e46fae5bffe0cf36a4092f048370a67f329))
* prevent SQL injection in Warner rule edit/delete (H2) ([e8383bf](https://github.com/stanstrup/QC4Metabolomics/commit/e8383bf16b5d859377d7ece5a4a15995743e5cb7))
* quote all IN/REGEXP values in Contaminants files_tbl_selected (H7) ([1c7f2bc](https://github.com/stanstrup/QC4Metabolomics/commit/1c7f2bc7b86107f4fcf28afe50e5bc7574ac677d))
* quote all IN/REGEXP/date values in Productivity heatmap queries (H10) ([868bd3d](https://github.com/stanstrup/QC4Metabolomics/commit/868bd3d7bccaf49e5f1c6de6e8bcdd64a36df7f6))
* quote date inputs in ICMeter timeplot query (H5) ([25f43f2](https://github.com/stanstrup/QC4Metabolomics/commit/25f43f22b4defcf9dac7e182c5011599460956bc))
* quote ion_id/mode/metric and validate mode in Contaminants time view (H9) ([0d4b056](https://github.com/stanstrup/QC4Metabolomics/commit/0d4b0568df98e438ed0dc19fbec18b4a9403e0a0))
* quote module names from env vars with dbQuoteString (L4) ([c58645f](https://github.com/stanstrup/QC4Metabolomics/commit/c58645f45d719f21a86d75591816bae83d3759ef))
* register output bindings once per plot id (M9 Productivity) ([70dd7df](https://github.com/stanstrup/QC4Metabolomics/commit/70dd7df9a296b48dbbf84f9956e288a22fc08d88))
* register output bindings once, linewidth instead of size (M9/M12 ICMeter) ([3f7c2b9](https://github.com/stanstrup/QC4Metabolomics/commit/3f7c2b972faea53f26b52465ab878eb4b2d5664d))
* remove plyr dependency, replace unrowname with as.data.frame(row.names=NULL) (L5) ([f90e566](https://github.com/stanstrup/QC4Metabolomics/commit/f90e56674fc34fe2eb84cdbde07b837de7db8ecd))
* removed code review file ([306bc46](https://github.com/stanstrup/QC4Metabolomics/commit/306bc46e1003caa2cc33affa2e956eed789f5c3a))
* replace deprecated aes_string() and size= in plots.R (M12) ([daedec5](https://github.com/stanstrup/QC4Metabolomics/commit/daedec5c6b20a32fa858d62d6342321cbec01150))
* replace gsub path-quoting with dbQuoteString in Files module (H11) ([d85a20e](https://github.com/stanstrup/QC4Metabolomics/commit/d85a20e2e11ef86cd0707cbd14c40471c1c14a75))
* replace spread() with pivot_wider() (L6 Contaminants overview) ([7abd19f](https://github.com/stanstrup/QC4Metabolomics/commit/7abd19f7b653edd06e1e5d67dc8152d1c7646a85))
* rm() on conditional exclude_path, remove normalizePath that broke relative paths (M7/M8) ([abfa166](https://github.com/stanstrup/QC4Metabolomics/commit/abfa1663bd517217f820980f12a626324b36f9e6))
* seq_len(nrow()) to avoid 1:0 crash, replace purrrlyr::by_row with pmap (M6/M11) ([5dc398f](https://github.com/stanstrup/QC4Metabolomics/commit/5dc398f5b5da8bab6d9b4c40a66fda141e5674c1))
* validate metric allowlist and quote file_md5 in Contaminants file screening (H6) ([fa01111](https://github.com/stanstrup/QC4Metabolomics/commit/fa011115f8301157a99bbc75cfd6938461c6312e))
* validate metric allowlist and quote md5/cut_off in Contaminants overview (H8) ([68f48de](https://github.com/stanstrup/QC4Metabolomics/commit/68f48dedff231fc93c93f462bd7dbca54150f434))
* VALUES alias, bounded while loop with per-device offset reset, pivot_longer (M2/M4/L6 ICMeter) ([2e077bb](https://github.com/stanstrup/QC4Metabolomics/commit/2e077bb0485bd9f93a03d23bd961bcb429f2bcd4))
* write_to_log null-pool bug and rem_dead_files per-DELETE commit (L2, L3) ([59b1b6b](https://github.com/stanstrup/QC4Metabolomics/commit/59b1b6b223d314108ce4d2556843f056e16bb168))

## [1.1.2](https://github.com/stanstrup/QC4Metabolomics/compare/v1.1.1...v1.1.2) (2026-08-31)


### Bug Fixes

* use reactiveVal pattern, rem_dead_files, and write_to_log in Admin ([f2d4463](https://github.com/stanstrup/QC4Metabolomics/commit/f2d44632142457e70bbec36fd70535116ea4235f))

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
