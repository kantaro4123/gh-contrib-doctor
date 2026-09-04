# gh-contrib-doctor

[![CI](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/ci.yml/badge.svg)](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/ci.yml)
[![Integration](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/integration.yml/badge.svg)](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/integration.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Find out why your Git commits are missing from your GitHub contribution graph.**

`gh-contrib-doctor` is a lightweight GitHub CLI extension that checks the common reasons commits do not appear as GitHub contributions: author-email attribution, non-default branches, forks, and repository relationship issues.

```bash
gh extension install kantaro4123/gh-contrib-doctor
gh contrib-doctor
```

## Example

```text
gh-contrib-doctor v0.1.0

Repository
  ✓ GitHub CLI authenticated as @octocat
  ✓ octocat/example is a standalone repository
  ✓ Default branch: main

Git identity
  ✓ octocat@example.com is a GitHub-allowed commit email for @octocat

Commits (since 1 year ago)
  · 49 likely commit(s) match your current Git identity
  ✓ 42 likely commit(s) are reachable from the default branch or local gh-pages branch
  ✗ 7 likely commit(s) exist only outside the default/gh-pages branches

Diagnosis
  ✗ 1 definite blocker(s) found
```

## What it checks

- GitHub CLI authentication and the current repository
- Whether the repository is a standalone repository or a fork
- The repository's default branch and local `gh-pages` branch
- Whether your configured Git author email is allowed for the authenticated GitHub user
- Commits from your likely Git identity that only exist outside contribution-eligible branches
- Historical author emails that may no longer be attributed to your account
- Repository relationship and private-contribution caveats
- GitHub's documented delay before newly qualifying contributions appear

GitHub's documented rules remain the source of truth. See [Profile contributions reference](https://docs.github.com/en/account-and-profile/reference/profile-contributions-reference) and [Troubleshooting missing contributions](https://docs.github.com/en/account-and-profile/how-tos/contribution-settings/troubleshooting-missing-contributions).

For email checks, the extension uses GitHub's `viewerPossibleCommitEmails` repository field when available and falls back to commit attribution metadata when necessary.

## Usage

Run it from inside a Git repository:

```bash
gh contrib-doctor
```

The default analysis window is one year, matching the usual GitHub profile contribution view.

```bash
# Any date expression accepted by git log
gh contrib-doctor --since "6 months ago"

# Analyze complete local history
gh contrib-doctor --all-time

# Other commands
gh contrib-doctor --version
gh contrib-doctor --help
```

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | No definite blocker was found |
| `1` | At least one definite contribution blocker was found |
| `2` | The doctor could not run |

Warnings and unknown checks do not by themselves produce exit code `1`.

## Requirements

- Git
- [GitHub CLI](https://cli.github.com/) authenticated with a user account (`gh auth login`)
- Bash

The extension has no package-manager or runtime dependencies beyond those tools.

## Privacy

Repository contents are not uploaded to any third-party service. The extension reads local Git metadata and uses your existing GitHub CLI authentication to query GitHub repository and commit metadata.

## Limitations

`gh-contrib-doctor` diagnoses contribution rules that can be checked from a local clone and the GitHub API; it does not reproduce GitHub's contribution graph internally.

Historical commits made with both a different author name and a different email from your current local Git identity may not be recognized automatically. Squashes, rebases, rewritten history, shallow clones, stale remote-tracking branches, and unpushed commits can also limit diagnosis.

A local `gh-pages` branch is treated as potentially contribution-eligible, but GitHub only applies the special `gh-pages` rule when it is used for a project site.

## Development

```bash
bash -n gh-contrib-doctor
bash tests/run.sh
```

CI runs the test suite and a real `gh extension install .` smoke test on Linux and macOS. A separate integration workflow exercises the live GitHub repository APIs available to GitHub Actions. The full diagnostic itself requires a user-authenticated `gh` session because the repository-scoped Actions token cannot identify a GitHub user.

## License

MIT
