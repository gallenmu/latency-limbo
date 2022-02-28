#!/bin/bash

# exit on error
set -e
# log every command
set -x

# install dependencies
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y zstd

# load vars
GIT_REPO=$(pos_get_variable -g moongen/repo)
GIT_BRANCH=$(pos_get_variable -g moongen/branch)
GIT_COMMIT=$(pos_get_variable -g moongen/commit)
MOONGEN=moongen

# install moongen
if [[ ! -e "$MOONGEN" ]]
then
	git clone --jobs 4 --recurse-submodules --branch "$GIT_BRANCH"  "$GIT_REPO" "$MOONGEN"
fi
cd "$MOONGEN"
git checkout "$GIT_COMMIT"
./build.sh
./bind-interfaces.sh
./setup-hugetlbfs.sh

echo "timer prepared $(date)"
