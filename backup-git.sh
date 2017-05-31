#!/bin/bash

set -eux
GITDIR=/home/git
TEMPDIR=/tmp

if [ $# -lt 1 ]; then
  echo "Usage: $0 BUCKETNAME"
  exit 1
fi

BUCKET="$1"

# Renice ourselves
renice -n 10 $$

# Clean things up when we're done
trap "rm -f ${TEMPDIR}/*.git.tar.xz" EXIT

cd $TEMPDIR

# create tar archives of each git repo
for proj in ${GITDIR}/*.git; do
    base=$(basename $proj)
    tar -C $GITDIR -cJf ${base}.tar.xz ${base}
done

upload() {
    if [ $# -gt 0 ]; then
        gsutil -q cp "$@" "${BUCKET}"
    fi
}

# If hashes.txt exists, only upload files whose hashes have changed. Otherwise,
# upload everything.
if [ -f hashes.txt ]; then
    upload $(sha1sum -c hashes.txt 2>/dev/null | awk -F: '/FAILED/ {print $1}')
else
    upload *.git.tar.xz
fi

# Write out the new file hashes for the next run.
sha1sum *.git.tar.xz >hashes.txt
