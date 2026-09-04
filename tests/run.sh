#!/usr/bin/env bash
set -u
set -o pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DOCTOR="$ROOT/gh-contrib-doctor"
TMP_ROOT=$(mktemp -d 2>/dev/null || mktemp -d -t gh-contrib-doctor-tests)
MOCK_BIN="$TMP_ROOT/bin"
PASS=0
FAIL=0

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT INT TERM

mkdir -p "$MOCK_BIN"

cat > "$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env bash
set -u

if [ "${1:-}" = "api" ] && [ "${2:-}" = "user" ]; then
  printf 'testuser\t12345\n'
  exit 0
fi

if [ "${1:-}" = "api" ] && [ "${2:-}" = "user/emails" ]; then
  if [ "${MOCK_EMAIL_SCOPE:-1}" = "0" ]; then
    exit 1
  fi
  printf '%s\n' "${MOCK_LINKED_EMAILS:-test@example.com}"
  exit 0
fi

if [ "${1:-}" = "repo" ] && [ "${2:-}" = "view" ]; then
  printf 'test/repo\tmain\t%s\t%s\t%s\n' \
    "${MOCK_IS_FORK:-false}" \
    "${MOCK_VISIBILITY:-PUBLIC}" \
    "${MOCK_PERMISSION:-ADMIN}"
  exit 0
fi

if [ "${1:-}" = "api" ]; then
  case "${2:-}" in
    repos/test/repo/commits/*)
      printf '%s\n' "${MOCK_COMMIT_LOGIN:-testuser}"
      exit 0
      ;;
  esac
fi

printf 'unexpected gh invocation:' >&2
printf ' %q' "$@" >&2
printf '\n' >&2
exit 1
MOCK
chmod +x "$MOCK_BIN/gh"

pass() {
  PASS=$((PASS + 1))
  printf 'ok - %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf 'not ok - %s\n' "$1" >&2
}

assert_status() {
  name="$1"
  expected="$2"
  actual="$3"
  if [ "$expected" -eq "$actual" ]; then
    pass "$name"
  else
    fail "$name (expected status $expected, got $actual)"
  fi
}

assert_contains() {
  name="$1"
  haystack="$2"
  needle="$3"
  if printf '%s\n' "$haystack" | grep -Fq -- "$needle"; then
    pass "$name"
  else
    fail "$name (missing: $needle)"
    printf '%s\n' "$haystack" >&2
  fi
}

new_repo() {
  repo="$1"
  mkdir -p "$repo"
  git init -q "$repo"
  (
    cd "$repo" || exit 1
    git checkout -q -b main
    git config user.name "Test User"
    git config user.email "test@example.com"
    printf 'initial\n' > file.txt
    git add file.txt
    git commit -qm "initial"
  )
}

run_doctor() {
  repo="$1"
  shift
  (
    cd "$repo" || exit 2
    PATH="$MOCK_BIN:$PATH" NO_COLOR=1 "$DOCTOR" "$@"
  ) 2>&1
}

# --version
output=$(NO_COLOR=1 "$DOCTOR" --version 2>&1)
status=$?
assert_status "version exits 0" 0 "$status"
assert_contains "version prints semantic version" "$output" "gh-contrib-doctor 0.1.0"

# Clean repository
repo="$TMP_ROOT/clean"
new_repo "$repo"
output=$(MOCK_LINKED_EMAILS="test@example.com" run_doctor "$repo")
status=$?
assert_status "clean repository exits 0" 0 "$status"
assert_contains "clean repository reports no blockers" "$output" "No definite contribution blockers found"
assert_contains "clean repository recognizes default branch" "$output" "Default branch: main"

# Commit only on a feature branch
repo="$TMP_ROOT/branch-only"
new_repo "$repo"
(
  cd "$repo" || exit 1
  git checkout -qb feature
  printf 'feature\n' >> file.txt
  git add file.txt
  git commit -qm "feature"
)
output=$(MOCK_LINKED_EMAILS="test@example.com" run_doctor "$repo")
status=$?
assert_status "branch-only commit exits 1" 1 "$status"
assert_contains "branch-only commit is diagnosed" "$output" "likely commit(s) exist only outside the default/gh-pages branches"

# Forks are definite blockers
repo="$TMP_ROOT/fork"
new_repo "$repo"
output=$(MOCK_IS_FORK=true MOCK_LINKED_EMAILS="test@example.com" run_doctor "$repo")
status=$?
assert_status "fork exits 1" 1 "$status"
assert_contains "fork is diagnosed" "$output" "is a fork"

# Unlinked configured email
repo="$TMP_ROOT/unlinked"
new_repo "$repo"
output=$(MOCK_LINKED_EMAILS="other@example.com" run_doctor "$repo")
status=$?
assert_status "unlinked email exits 1" 1 "$status"
assert_contains "unlinked email is diagnosed" "$output" "test@example.com is not linked to @testuser"

# Email-list permission fallback via commit attribution
repo="$TMP_ROOT/fallback"
new_repo "$repo"
output=$(MOCK_EMAIL_SCOPE=0 MOCK_COMMIT_LOGIN=testuser run_doctor "$repo")
status=$?
assert_status "commit-attribution fallback exits 0" 0 "$status"
assert_contains "fallback recognizes GitHub attribution" "$output" "GitHub attributes commits using test@example.com to @testuser"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
