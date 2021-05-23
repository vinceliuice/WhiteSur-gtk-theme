#! /usr/bin/env bash
#
# Clean ignored files
#

# TODO: integrate with Bridge.sh

git clean -d -f -X
git add .
