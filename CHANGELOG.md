# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-27

### Removed

- `FairPick.expand_pool/1` — made private; implementation detail, not part of the public API
- `FairPick.shuffle/2` — made private; implementation detail, not part of the public API

### Changed

- `FairPick.PRNG` marked `@moduledoc false`; module is not part of the public API surface

## [0.1.0] - 2026-03-24

### Added

- `FairPick.draw/3` — deterministic draw with entry validation, pool expansion, shuffle, deduplication
- `FairPick.expand_pool/1` — sort entries by ID and expand weights into flat pool
- `FairPick.shuffle/2` — Durstenfeld (modern Fisher-Yates) shuffle with PRNG
- `FairPick.PRNG` — SHA256 counter-mode PRNG with rejection sampling
- Algorithm test vectors A-1 through A-5 (frozen, canonical)
- GitHub Actions CI (format, credo, tests)
