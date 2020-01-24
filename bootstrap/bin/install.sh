#!/usr/local/bin/bash

export BUILD_HARNESS_ORG=${1:-plus3it}
export BUILD_HARNESS_PROJECT=${2:-tardigrad-ci}
export BUILD_HARNESS_BRANCH=${3:-master}
export GITHUB_REPO="https://github.com/${BUILD_HARNESS_ORG}/${BUILD_HARNESS_PROJECT}.git"

if [ "$BUILD_HARNESS_PROJECT" ] && [ -d "$BUILD_HARNESS_PROJECT" ]; then
  echo "Removing existing $BUILD_HARNESS_PROJECT"
  rm -rf "$BUILD_HARNESS_PROJECT"
fi

echo "Cloning ${GITHUB_REPO}#${BUILD_HARNESS_BRANCH}..."

git clone -b "$BUILD_HARNESS_BRANCH" "$GITHUB_REPO"
