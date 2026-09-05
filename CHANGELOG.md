# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- `--json` output for CI, scripts, and editor integrations.
- `--strict` mode to fail when a diagnostic remains uncertain or warning-level.
- `--no-color` for deterministic plain-text output.
- Explicit shallow-clone diagnostics.
- Regression coverage for commits that exist on local `main` but have not reached GitHub.

### Changed

- Branch eligibility now uses the actual GitHub default-branch and `gh-pages` head SHAs instead of trusting local branch names or a particular remote name.
- CI and live integration workflows now use the current Node 24-based checkout action.
- Live integration verifies the same GitHub branch-head API used by the doctor.

### Fixed

- Local-only commits on a default-named branch can no longer be reported as contribution-eligible merely because they are reachable from local `main`.
- JSON escaping and machine-readable output are covered by regression tests.

## [0.1.0] - 2026-09-05

### Added

- Initial `gh contrib-doctor` command.
- Checks for forks, default-branch eligibility, Git author email attribution, and private-repository visibility.
- Email verification via GitHub's `viewerPossibleCommitEmails`, with commit-attribution fallback.
- `--since`, `--all-time`, `--help`, and `--version` options.
- Dependency-free test suite for clean, branch-only, fork, and email-attribution scenarios.
- GitHub Actions CI on Linux and macOS, including a real extension-install smoke test.
