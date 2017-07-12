#!/bin/bash
# Copyright 2017, Evan Klitzke <evan@eklitzke.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
