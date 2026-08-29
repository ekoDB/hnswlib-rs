# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Releases are tagged `vX.Y.Z` on master; unreleased work accumulates under `[Unreleased]` and is converted to a dated version block at release. History from before the ekoDB fork is preserved verbatim at the bottom, imported from the upstream project's `Changes.md` (upstream did not record dates).

## [Unreleased]

### Changed

- **`rust-toolchain.toml` comment no longer names internal repositories.** The comment explaining the pin referred to two internal ekoDB repositories by name in a file that is readable by anyone; it now refers to the other ekoDB Rust repos generically. Comment text only: the pinned toolchain (1.95.0), the `rustfmt` and `clippy` components, and the `minimal` profile are all unchanged.

## [0.5.0] - 2026-07-02

### Added

- **Soft-deletion with neighbor repair** - `mark_deleted()` scans all layers so deleted points cannot reappear from any level; search-layer optimizations; deletion test suite.
- **Smart bulk insert methods** - `bulk_insert_slice` and friends for efficient data insertion (sequential below a parallelism threshold, parallel above it).
- **GitHub Actions CI** - rustfmt check, clippy `-D warnings`, and `cargo test --locked` on push/PR to master, pinned to Rust 1.95.0 on x86_64, with `libhdf5-dev` installed for the hdf5 dev-dependency the examples compile against (#2).
- **Pull request template** with a reviewer checklist.
- **Makefile** with the standard targets used across ekoDB Rust repos (`setup`, `build`, `test`, `fmt`, `lint`, `deps-check`, `deps-update`, `audit`, `set-version`); `make lint` and `make test` run exactly what CI runs, and `make test-x86` runs lib + integration tests under Rosetta on Apple Silicon.
- **Fork documentation in README**: what the crate is used for, why the fork exists, the relationship to upstream, and the development workflow, plus a CI badge.
- **Pre-commit git hook** (`scripts/pre-commit`, installed via `make install-hooks`) running the CI-matching lint and tests before every commit.

### Changed

- **SIMD (`simdeez_f`) enabled by default**; anndists is now consumed from the ekoDB fork.
- **`Cargo.lock` is now tracked** (required for reproducible `--locked` CI; consumers are unaffected since this crate is consumed as a pinned git dependency) and refreshed to the latest compatible versions.
- **Dependency bumps**: hashbrown 0.15 to 0.17, hdf5-metno 0.12 to 0.13. skiplist stays at 0.6 because 1.x requires `Ord` on element types while `PointIdWithOrder` orders by an f32 distance (`PartialOrd` only).
- **anndists pinned to the fork's v0.2.0**, picking up the out-of-bounds fix in the SIMD L1/L2 residual loops that panicked seven of this crate's tests on x86_64.
- **Lint cleanups** (behavior-preserving): if-let instead of `is_some()`/`unwrap()` pairs, unit-struct construction without `default()`, `is_multiple_of` for the counter check, ignore the `env_logger::try_init` result in the ann-glove example, rustfmt on `hnsw.rs` and `deletion_test.rs`.

### Removed

- **bincode dependency** (RUSTSEC-2025-0141).

---

## Pre-fork upstream history

Imported verbatim from the upstream `Changes.md`.

- version 0.3.4
  small fix in reloading with DataMap in case dump directory given by a relative path (thanks to dsgallups)
  update deps.

- version 0.3.3
  small fix on filter (thanks to VillSnow). include ndarray 0.17 as possible dep. fixed compiler warning on elided lifetimes

- version 0.3.2
  update dependencies to ndarray 0.16 , rand 0.9 indexmap 2.9, hdf5. edition=2024

- version 0.3.1

  Possibility to reduce the number of levels used Hnsw structure with the function hnsw::modify*level_scale.
  This often increases significantly recall while incurring a moderate cpu cost. It is also possible
  to have same recall with smaller \_max_nb_conn* parameters so reducing memory usage.
  See README.md at [bigann](https://github.com/jean-pierreBoth/bigann).
  Modification inspired by the article by [Munyampirwa](https://arxiv.org/abs/2412.01940)

  Clippy cleaning and minor arguments change (PathBuf to Path String to &str) in dump/reload
  with the help of bwsw [github](https://github.com/bwsw)

- **version 0.3.0**:

  The distances implementation is now in a separate crate [anndsits](https://crates.io/crates/anndists). Using hnsw_rs::prelude:::\* should make the change transparent.

  The mmap implementation makes it possible to use the [coreset](https://github.com/jean-pierreBoth/coreset) crate to compute coreset and clusters of data stored in hnsw dumps.

- version 0.2.1:

  when using mmap, the points less frequently used (points in lower layers) are preferentially mmap-ed while upper layers are preferentially
  explcitly read from file.

  Hnswio is now Sync.

  feature stdsimd, based on std::simd, runs with nightly on Hamming with u32,u64 and DisL1,DistL2, DistDot with f32

- The **version 0.2** introduces:
  1. possibility to use mmap on the data file storing the vectors represented in the hnsw structure. This is mostly usefule for
     large vectors, where data needs more space than the graph part.
     As a consequence the format of this file changed. Old format can be read but new dumps will be in the new format.
     In case of mmap usage, a dump after inserting new elements must ensure that the old file is not overwritten, so a unique file name is
     generated if necessary. See documentation of module Hnswio

  1. the filtering trait

- Upgrade of many dependencies. Change from simple*logger to env_logger. The logger is initialized one for all in file src/lib.rs and cannot be intialized twice. The level of log can be modulated by the RUST_LOG env variable on a module basis or switched off. See the \_env_logger* crate doc.

- A rust crate _edlib_rs_ provides an interface to the _excellent_ edlib C++ library [(Cf edlib)](https://github.com/Martinsos/edlib) can be found at [edlib_rs](https://github.com/jean-pierreBoth/edlib-rs) or on crate.io. It can be used to define a user adhoc distance on &[u8] with normal, prefix or infix mode (which is useful in genomics alignment).

- The library do not depend anymore on hdf5 and ndarray. They are dev-dependancies needed for examples, this simplify compatibility issues.
- Added insertion methods for slices for easier use with the ndarray crate.

- simd/avx2 requires now the feature "simdeez_f". So by default the crate can compile on M1 chip and transitions to std::simd.

- Added DistPtr and possiblity to dump/reload with this distance type. (See _load_hnsw_with_dist_ function)

- Implementation of Hamming for f64 exclusively in the context SuperMinHash in crate [probminhash](https://crates.io/crates/probminhash)
