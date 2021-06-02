#! /usr/bin/env bash
#
# Clean ignored files
#

# TODO: integrate with Bridge.sh

git clean -d -f -X
git add .

! command -v beautysh && sudo pip install beautysh
beautysh -i 2 -s paronly *.sh

git add .

echo "DONE!"
