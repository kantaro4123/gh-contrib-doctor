# gh-contrib-doctor

[![CI](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/ci.yml/badge.svg)](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/ci.yml)
[![Integration](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/integration.yml/badge.svg)](https://github.com/kantaro4123/gh-contrib-doctor/actions/workflows/integration.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Find out why your Git commits are missing from your GitHub contribution graph.**

`gh-contrib-doctor` is a lightweight GitHub CLI extension that checks the common reasons commits do not appear as GitHub contributions: author-email attribution, commits that have not reached GitHub's eligible branch heads, forks, repository relationship issues, and incomplete local history.

```bash
gh extension install kantaro4123/gh-contrib-doctor
gh contrib-doctor
```

## Example

```text
Repository
  ✓ GitHub CLI authenticated as @octocat
  ✓ octocat/example is a standalone repository
  ✓ Default branch: main

Git identity
  ✓ octocat@example.com is a GitHub-allowed commit email for @octocat

Commits (since 1 year ago)
  · 49 likely commit(s) match your current Git identity
  ✓ 42 likely commit(s) are reachable from GitHub's default branch or gh-pages head
  ✗ 7 likely commit(s) are not reachable from GitHub's default/gh-pages branch heads

Diagnosis
  ✗ 1 definite blocker(s) found
```

This matters for a subtle case that simple local checks miss: a commit can be on your local `main` while still not being pushed to GitHub. The doctor compares against the **actual branch head SHA reported by GitHub**, not merely the local branch name.

## What it checks

- GitHub CLI authentication and the current repository
- Whether the repository is a standalone repository or a fork
- GitHub's actual default-branch head and, when present, `gh-pages` head
- Whether your configured Git author email is allowed for the authenticated GitHub user
- Commits from your likely Git identity that have not reached GitHub's contribution-eligible branch heads
- Historical author emails that may no longer be attributed to your account
- Repository relationship and private-contribution caveats
- Shallow clones and missing branch objects that make diagnosis incomplete
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

# Machine-readable output
gh contrib-doctor --json

# Make warnings fail CI too
gh contrib-doctor --strict

# Stable plain-text output without ANSI escapes
gh contrib-doctor --no-color

# Other commands
gh contrib-doctor --version
gh contrib-doctor --help
```

## JSON output

`--json` exposes the same diagnosis in a stable machine-readable shape:

```json
{
  "repository": "octocat/example",
  "default_branch": "main",
  "fork": false,
  "shallow": false,
  "git_identity": {
    "email": "octocat@example.com",
    "email_status": "linked"
  },
  "commits": {
    "matched": 49,
    "eligible": 42,
    "not_on_github_eligible_branches": 7,
    "branch_analysis_available": true
  },
  "summary": {
    "blockers": 1,
    "warnings": 0,
    "ready": false
  }
}
```

That makes the extension usable in shell scripts, CI checks, and higher-level developer tooling without parsing terminal text.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | No definite blocker was found |
| `1` | At least one definite blocker was found, or a warning was found with `--strict` |
| `2` | The doctor could not run |

Warnings and unknown checks do not by themselves produce exit code `1` unless `--strict` is used.

## Requirements

- Git
- [GitHub CLI](https://cli.github.com/) authenticated with a user account (`gh auth login`)
- Bash

The extension has no package-manager or runtime dependencies beyond those tools.

## Privacy

Repository contents are not uploaded to any third-party service. The extension reads local Git metadata and uses your existing GitHub CLI authentication to query GitHub repository, branch, and commit metadata.

## Limitations

`gh-contrib-doctor` diagnoses contribution rules that can be checked from a local clone and the GitHub API; it does not reproduce GitHub's contribution graph internally.

Historical commits made with both a different author name and a different email from your current local Git identity may not be recognized automatically. Squashes, rebases, rewritten history, and shallow clones can also limit diagnosis.

If GitHub's current branch head object is missing from the local clone, the doctor refuses to guess and warns you to run `git fetch --all` instead of treating a similarly named local branch as authoritative.

The `gh-pages` branch is treated as potentially contribution-eligible when it exists on GitHub, but GitHub only applies the special rule when it is used for a project site.

## Development

```bash
bash -n gh-contrib-doctor
bash tests/run.sh
```

CI runs the test suite and a real `gh extension install .` smoke test on Linux and macOS. A separate integration workflow exercises the live GitHub repository and branch-head APIs available to GitHub Actions. The full diagnostic itself requires a user-authenticated `gh` session because the repository-scoped Actions token cannot identify a GitHub user.

## License

MIT
