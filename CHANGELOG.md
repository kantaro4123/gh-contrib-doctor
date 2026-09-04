# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-09-05

### Added

- Initial `gh contrib-doctor` command.
- Checks for forks, default-branch eligibility, Git author email attribution, and private-repository visibility.
- Email verification via GitHub's `viewerPossibleCommitEmails`, with commit-attribution fallback.
- `--since`, `--all-time`, `--help`, and `--version` options.
- Dependency-free test suite for clean, branch-only, fork, and email-attribution scenarios.
- GitHub Actions CI on Linux and macOS, including a real extension-install smoke test.
