#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

SRC_FILE="thumbnail.svg"

[[ -f thumbnail-light.png ]] && rm -rf thumbnail-light.png
echo Rendering thumbnail-light.png

$INKSCAPE --export-id=thumbnail-light --export-id-only --export-filename=thumbnail-light.png $SRC_FILE >/dev/null
$OPTIPNG -o7 --quiet thumbnail-light.png 

[[ -f thumbnail-dark.png ]] && rm -rf thumbnail-dark.png
echo Rendering thumbnail-dark.png
$INKSCAPE --export-id=thumbnail-dark --export-id-only --export-filename=thumbnail-dark.png $SRC_FILE >/dev/null
$OPTIPNG -o7 --quiet thumbnail-dark.png 

exit 0
