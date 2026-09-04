# gh-contrib-doctor

Diagnose why your Git commits may be missing from your GitHub contribution graph.

`gh-contrib-doctor` is a lightweight [GitHub CLI](https://cli.github.com/) extension. It checks the rules GitHub documents for commit contributions and points out the most common blockers: author-email attribution, non-default branches, forks, and private-repository visibility.

> Status: early development (`v0.1.0`). The repository is intentionally private until the first release is verified.

## What it checks

- GitHub CLI authentication and the current repository
- Whether the repository is a standalone repository or a fork
- The repository's default branch and local `gh-pages` branch
- Whether your configured Git author email is one GitHub allows the authenticated user to commit with
- Likely commits from your local Git identity that exist only outside contribution-eligible branches
- Historical author emails matching your current Git author name that may no longer be attributed to your account
- Private-repository visibility caveats
- The up-to-24-hour delay GitHub documents for newly qualifying commits

GitHub's documented criteria are the source of truth: a commit must use an email associated with your account, be in a standalone repository, and be on the default branch or `gh-pages` (for a project site). GitHub also applies an account/repository relationship requirement. See [Profile contributions reference](https://docs.github.com/en/account-and-profile/reference/profile-contributions-reference) and [Troubleshooting missing contributions](https://docs.github.com/en/account-and-profile/how-tos/contribution-settings/troubleshooting-missing-contributions).

For email checks, the extension uses GitHub's `viewerPossibleCommitEmails` repository field, which GitHub defines as the emails the current viewer can commit with. If that field is unavailable, the doctor falls back to the author attribution on a matching commit.

## Install

```bash
gh extension install kantaro4123/gh-contrib-doctor
```

Then run it from inside a Git repository:

```bash
gh contrib-doctor
```

By default, the doctor analyzes the last year, matching the time window shown on the GitHub profile contribution graph.

```bash
# Use any date expression accepted by git log
gh contrib-doctor --since "6 months ago"

# Analyze the complete local history
gh contrib-doctor --all-time
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

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | No definite blocker was found |
| `1` | At least one definite contribution blocker was found |
| `2` | The doctor could not run (for example, not in a Git repository or GitHub CLI is not authenticated) |

Warnings and unknown checks do not by themselves produce exit code `1`.

## Privacy

The extension does not send repository contents anywhere. It reads local Git metadata and uses your existing `gh` authentication to query GitHub repository and commit metadata. No third-party service is used.

## Limitations

`gh-contrib-doctor` diagnoses the common commit-contribution rules that can be checked from a local clone and the GitHub API. It does not attempt to reproduce GitHub's contribution graph internally.

Historical commits made with both a different author name and a different email from your current local Git identity may not be recognized as yours automatically. Squashes, rebases, rewritten history, shallow clones, stale remote-tracking branches, and commits that have not been pushed can also limit what can be diagnosed.

A local `gh-pages` branch is treated as potentially contribution-eligible, but GitHub only applies the special `gh-pages` rule when it is used for a project site.

## Development

The extension is intentionally dependency-free beyond Bash, Git, and GitHub CLI.

```bash
bash -n gh-contrib-doctor
bash tests/run.sh
```

CI runs the test suite and a real `gh extension install .` smoke test on both Linux and macOS.

## License

MIT
