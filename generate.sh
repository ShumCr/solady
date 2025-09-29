#!/bin/bash

# Exit on error
set -e

# Number of iterations (commits)
ITERATIONS=5

# Main branch name
MAIN_BRANCH="main"

# Make sure we are on main and up to date
git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH

for i in $(seq 1 $ITERATIONS)
do
    BRANCH_NAME="feature-branch-$i"

    echo "=== Iteration $i: Working on branch $BRANCH_NAME ==="

    # Create a new branch
    git checkout -b $BRANCH_NAME

    # Generate a file with timestamp
    FILENAME="file_$i.txt"
    echo "This is file $i generated at $(date)" > $FILENAME

    # Stage and commit the file
    git add $FILENAME
    git commit -m "Add $FILENAME"

    # Push branch to remote
    git push origin $BRANCH_NAME

    # Switch back to main and merge
    git checkout $MAIN_BRANCH
    git pull origin $MAIN_BRANCH
    git merge --no-ff $BRANCH_NAME -m "Merge branch '$BRANCH_NAME' into $MAIN_BRANCH"

    # Push main branch
    git push origin $MAIN_BRANCH

    # Optionally delete the feature branch locally & remotely
    git branch -d $BRANCH_NAME
    git push origin --delete $BRANCH_NAME

    echo "=== Iteration $i completed ==="
    echo
done
