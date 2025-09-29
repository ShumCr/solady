#!/usr/bin/env bash
set -euo pipefail

# ---------- CONFIG ----------
ITERATIONS=${ITERATIONS:-5}           # number of commits/merges to create
MAIN_BRANCH=${MAIN_BRANCH:-main}     # your main branch name (change to master if needed)
REMOTE=${REMOTE:-origin}             # remote name
AUTHOR_NAME=${AUTHOR_NAME:-}         # optional: set to your GitHub display name
AUTHOR_EMAIL=${AUTHOR_EMAIL:-}       # optional: set to your GitHub email (must match GitHub account for contributions)
# If you want to adjust commit timestamps for contribution graph, set COMMIT_DATE (RFC3339 or "YYYY-MM-DDTHH:MM:SS")
# Example: COMMIT_DATE="2022-12-01T08:30:00+00:00"
COMMIT_DATE=${COMMIT_DATE:-}

# ---------- sanity checks ----------
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: this script must be run from inside a git repository."
  exit 1
fi

# Make sure working tree is clean
if [[ -n $(git status --porcelain) ]]; then
  echo "ERROR: please commit or stash your changes before running this script."
  git status --porcelain
  exit 1
fi

# Ensure main branch exists locally
if ! git show-ref --verify --quiet "refs/heads/$MAIN_BRANCH"; then
  echo "ERROR: local branch '$MAIN_BRANCH' not found."
  exit 1
fi

# Ensure remote exists
if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "ERROR: remote '$REMOTE' not found."
  exit 1
fi

# ---------- loop ----------
for i in $(seq 1 "$ITERATIONS"); do
  BRANCH="feature/eth-contract-${i}"
  CONTRACT_DIR="contracts"
  CONTRACT_FILE="${CONTRACT_DIR}/SimpleStorage_${i}.sol"

  echo
  echo "=== Iteration $i: branch $BRANCH -> create $CONTRACT_FILE ==="

  # update main and create branch
  git checkout "$MAIN_BRANCH"
  git pull "$REMOTE" "$MAIN_BRANCH"

  git checkout -b "$BRANCH"

  mkdir -p "$CONTRACT_DIR"

  # write a small Solidity contract (SimpleStorage with an event)
  cat > "$CONTRACT_FILE" <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title SimpleStorage - tiny example contract
/// @notice Stores a single uint256 and emits an event on change
contract SimpleStorage {
    uint256 public value;
    event ValueChanged(uint256 indexed newValue, address indexed changedBy);

    /// @notice Set a new value
    /// @param _value new value to store
    function set(uint256 _value) external {
        value = _value;
        emit ValueChanged(_value, msg.sender);
    }
}
EOF

  # Stage file
  git add "$CONTRACT_FILE"

  # Prepare author flags / env for commit
  COMMIT_MSG="feat: add SimpleStorage contract (${i})"

  # If user provided explicit author, use --author; otherwise rely on git config
  if [[ -n "$AUTHOR_NAME" && -n "$AUTHOR_EMAIL" ]]; then
    AUTHOR_FLAG="--author=${AUTHOR_NAME} <${AUTHOR_EMAIL}>"
    echo "Committing as ${AUTHOR_NAME} <${AUTHOR_EMAIL}>"
  else
    AUTHOR_FLAG=""
    echo "Committing using git config user.name/user.email"
  fi

  # If COMMIT_DATE set, set GIT_AUTHOR_DATE and GIT_COMMITTER_DATE
  if [[ -n "$COMMIT_DATE" ]]; then
    export GIT_AUTHOR_DATE="$COMMIT_DATE"
    export GIT_COMMITTER_DATE="$COMMIT_DATE"
    echo "Using commit date: $COMMIT_DATE"
  else
    unset GIT_AUTHOR_DATE || true
    unset GIT_COMMITTER_DATE || true
  fi

  # Perform commit
  if [[ -n "$AUTHOR_FLAG" ]]; then
    git commit $AUTHOR_FLAG -m "$COMMIT_MSG"
  else
    git commit -m "$COMMIT_MSG"
  fi

  # push branch
  git push "$REMOTE" "$BRANCH"

  # Merge into main via merge commit (no-ff) and push
  git checkout "$MAIN_BRANCH"
  git pull "$REMOTE" "$MAIN_BRANCH"
  git merge --no-ff "$BRANCH" -m "Merge ${BRANCH} into ${MAIN_BRANCH} (SimpleStorage ${i})"
  git push "$REMOTE" "$MAIN_BRANCH"

  # Optional: delete feature branch locally and remotely
  git branch -d "$BRANCH"
  git push "$REMOTE" --delete "$BRANCH" || echo "Warning: remote branch deletion failed (it may already be gone)"

  echo "=== Iteration $i complete ==="
done

echo
echo "All done. Created $ITERATIONS contracts and merged into $MAIN_BRANCH."
