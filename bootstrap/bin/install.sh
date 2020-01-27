#!/usr/local/bin/bash

export TARDIGRADE_CI_ORG=${1:-plus3it}
export TARDIGRADE_CI_PROJECT=${2:-tardigrade-ci}
export TARDIGRADE_CI_BRANCH=${3:-master}
export GITHUB_REPO="https://github.com/${TARDIGRADE_CI_ORG}/${TARDIGRADE_CI_PROJECT}.git"

if [ "$TARDIGRADE_CI_PROJECT" ] && [ -d "$TARDIGRADE_CI_PROJECT" ]; then
  echo "Removing existing $TARDIGRADE_CI_PROJECT"
  rm -rf "$TARDIGRADE_CI_PROJECT"
fi

echo "Cloning ${GITHUB_REPO}#${TARDIGRADE_CI_BRANCH}..."

git clone -b "$TARDIGRADE_CI_BRANCH" "$GITHUB_REPO"
