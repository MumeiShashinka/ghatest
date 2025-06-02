#!/usr/bin/env bash

# Manual testing:
# GITHUB_ACTIONS=false GITHUB_OUTPUT=output SUFFIX= DEVELOP=main GITHUB_REPOSITORY=tier4/WebAutoIaCGitHubActions ./tag-deployment.sh && cat output

set -euo pipefail

REPO_NAME="${GITHUB_REPOSITORY#*/}"
[ "$REPO_NAME" ] || { echo "No repository name ?!"; exit 1; }
echo "Repository name: $REPO_NAME"

BASE_SHA=$(git merge-base HEAD "refs/remotes/origin/${DEVELOP}")
[ "$BASE_SHA" ] || { echo "No merge base found!"; exit 1; }
echo "Merge base SHA: $BASE_SHA"

RELEASE_DATETIME=$(git log -1 --format=%cI "$BASE_SHA")
[ "$RELEASE_DATETIME" ] || { echo "No datetime found for the release!"; exit 1; }
echo "Commit date-time of merge base: $RELEASE_DATETIME"

RELEASE_DATE_UTC=$(date --utc --date="$RELEASE_DATETIME" +%Y-%m-%d | cut -d'T' -f1)
[ "$RELEASE_DATE_UTC" ] || { echo "No UTC date found for the release!"; exit 1; }
echo "Commit date in UTC: $RELEASE_DATE_UTC"

ALREADY_TAGGED=$(git tag --points-at HEAD "$RELEASE_DATE_UTC-p*")
if [[ "$ALREADY_TAGGED" ]]; then
  echo "Already tagged with: $ALREADY_TAGGED"
  echo "tag_value=$ALREADY_TAGGED" >> "$GITHUB_OUTPUT"
  exit 0
fi

CURRENT_PATCH=$(git tag --list "$RELEASE_DATE_UTC-p*" | sort | tail -n 1)
echo "Prior release on same day: $CURRENT_PATCH"
CURRENT_PATCH=$([[ "$CURRENT_PATCH" =~ -p([0-9]+)-.*$ ]] && echo "${BASH_REMATCH[1]}" || echo 0)
echo "Current patch number: $CURRENT_PATCH"
NEXT_PATCH=$((CURRENT_PATCH + 1))
echo "Next patch number: $NEXT_PATCH"
[[ -n "$SUFFIX" && ! "$SUFFIX" =~ ^[a-zA-Z0-9] ]] && { echo "Suffix must start with [a-zA-Z0-9]"; exit 1; }
SUFFIX=$([[ "$SUFFIX" ]] && echo "+$SUFFIX" || echo "")
echo "Suffix: $SUFFIX"
TAG_VALUE=$RELEASE_DATE_UTC-p$NEXT_PATCH-$REPO_NAME$SUFFIX
echo "New version tag value: $TAG_VALUE"
echo "tag_value=$TAG_VALUE" >> "$GITHUB_OUTPUT"

if [ "$GITHUB_ACTIONS" == "true" ]; then
  echo "Pushing tag..."
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git tag "$TAG_VALUE"
  git push origin tag "$TAG_VALUE"
fi
