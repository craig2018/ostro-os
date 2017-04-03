#!/bin/bash
#
# Build performance test script wrapper
#
# Copyright (c) 2016, Intel Corporation.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
#
# This script is a simple wrapper around the actual build performance tester
# script. This script initializes the build environment, runs
# oe-build-perf-test and archives the results.

script=`basename $0`
archive_dir=~/perf-results/archives

usage () {
cat << EOF
Usage: $script [-h] [-c COMMITISH] [-C GIT_REPO]

Optional arguments:
  -h                show this help and exit.
  -a ARCHIVE_DIR    archive results tarball here, give an empty string to
                    disable tarball archiving (default: $archive_dir)
  -c COMMITISH      test (checkout) this commit, <branch>:<commit> can be
                    specified to test specific commit of certain branch
  -C GIT_REPO       commit results into Git
  -w WORK_DIR       work dir for this script
                    (default: GIT_TOP_DIR/build-perf-test)
  -x                create xml report (instead of json)
EOF
}


# Parse command line arguments
commitish=""
oe_build_perf_test_extra_opts=()
while getopts "ha:c:C:w:x" opt; do
    case $opt in
        h)  usage
            exit 0
            ;;
        a)  archive_dir=`realpath -s "$OPTARG"`
            ;;
        c)  commitish=$OPTARG
            ;;
        C)  results_repo=`realpath -s "$OPTARG"`
            ;;
        w)  base_dir=`realpath -s "$OPTARG"`
            ;;
        x)  oe_build_perf_test_extra_opts+=("--xml")
            ;;
        *)  usage
            exit 1
            ;;
    esac
done

# Check positional args
shift "$((OPTIND - 1))"
if [ $# -ne 0 ]; then
    echo "ERROR: No positional args are accepted."
    usage
    exit 1
fi

# Open a file descriptor for flock and acquire lock
LOCK_FILE="/tmp/oe-build-perf-test-wrapper.lock"
if ! exec 3> "$LOCK_FILE"; then
    echo "ERROR: Unable to open lock file"
    exit 1
fi
if ! flock -n 3; then
    echo "ERROR: Another instance of this script is running"
    exit 1
fi

echo "Running on `uname -n`"
if ! git_topdir=$(git rev-parse --show-toplevel); then
        echo "The current working dir doesn't seem to be a git clone. Please cd there before running `basename $0`"
        exit 1
fi

cd "$git_topdir"

if [ -n "$commitish" ]; then
    echo "Running git fetch"
    git fetch &> /dev/null
    git checkout HEAD^0 &> /dev/null

    # Handle <branch>:<commit> format
    if echo "$commitish" | grep -q ":"; then
        commit=`echo "$commitish" | cut -d":" -f2`
        branch=`echo "$commitish" | cut -d":" -f1`
    else
        commit="$commitish"
        branch="$commitish"
    fi

    echo "Checking out $commitish"
    git branch -D $branch &> /dev/null
    if ! git checkout -f $branch &> /dev/null; then
        echo "ERROR: Git checkout failed"
        exit 1
    fi

    # Check that the specified branch really contains the commit
    commit_hash=`git rev-parse --revs-only $commit --`
    if [ -z "$commit_hash" -o "`git merge-base $branch $commit`" != "$commit_hash" ]; then
        echo "ERROR: branch $branch does not contain commit $commit"
        exit 1
    fi
    git reset --hard $commit > /dev/null
fi

# Setup build environment
if [ -z "$base_dir" ]; then
    base_dir="$git_topdir/build-perf-test"
fi
echo "Using working dir $base_dir"

timestamp=`date "+%Y%m%d%H%M%S"`
git_rev=$(git rev-parse --short HEAD)  || exit 1
build_dir="$base_dir/build-$git_rev-$timestamp"
results_dir="$base_dir/results-$git_rev-$timestamp"
globalres_log="$base_dir/globalres.log"
machine="qemux86"

mkdir -p "$base_dir"
source ./oe-init-build-env $build_dir >/dev/null || exit 1

# Additional config
auto_conf="$build_dir/conf/auto.conf"
echo "MACHINE = \"$machine\"" > "$auto_conf"
echo 'BB_NUMBER_THREADS = "8"' >> "$auto_conf"
echo 'PARALLEL_MAKE = "-j 8"' >> "$auto_conf"
echo "DL_DIR = \"$base_dir/downloads\"" >> "$auto_conf"
# Disabling network sanity check slightly reduces the variance of timing results
echo 'CONNECTIVITY_CHECK_URIS = ""' >> "$auto_conf"
# Possibility to define extra settings
if [ -f "$base_dir/auto.conf.extra" ]; then
    cat "$base_dir/auto.conf.extra" >> "$auto_conf"
fi

# Run actual test script
oe-build-perf-test --out-dir "$results_dir" \
                   --globalres-file "$globalres_log" \
                   "${oe_build_perf_test_extra_opts[@]}" \
                   --lock-file "$base_dir/oe-build-perf.lock"

case $? in
    1)  echo "ERROR: oe-build-perf-test script failed!"
        exit 1
        ;;
    2)  echo "NOTE: some tests failed!"
        ;;
esac

# Commit results to git
if [ -n "$results_repo" ]; then
    echo -e "\nArchiving results in $results_repo"
    oe-git-archive \
        --git-dir "$results_repo" \
        --branch-name "{hostname}/{branch}/{machine}" \
        --tag-name "{hostname}/{branch}/{machine}/{commit_count}-g{commit}/{tag_number}" \
        --exclude "buildstats.json" \
        --notes "buildstats/{branch_name}" "$results_dir/buildstats.json" \
        "$results_dir"
fi

echo -ne "\n\n-----------------\n"
echo "Global results file:"
echo -ne "\n"

cat "$globalres_log"

if [ -n "$archive_dir" ]; then
    echo -ne "\n\n-----------------\n"
    echo "Archiving results in $archive_dir"
    mkdir -p "$archive_dir"
    results_basename=`basename "$results_dir"`
    results_dirname=`dirname "$results_dir"`
    tar -czf "$archive_dir/`uname -n`-${results_basename}.tar.gz" -C "$results_dirname" "$results_basename"
fi

rm -rf "$build_dir"
rm -rf "$results_dir"

echo "DONE"
