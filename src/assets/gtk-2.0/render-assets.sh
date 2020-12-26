#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

LIGHT_SRC_FILE="assets-light.svg"
LIGHT_ASSETS_DIR="assets-light"

DARK_SRC_FILE="assets-dark.svg"
DARK_ASSETS_DIR="assets-dark"

INDEX="assets.txt"

[[ -d $LIGHT_ASSETS_DIR ]] && rm -rf $LIGHT_ASSETS_DIR
[[ -d $DARK_ASSETS_DIR ]] && rm -rf $DARK_ASSETS_DIR
mkdir -p $LIGHT_ASSETS_DIR && mkdir -p $DARK_ASSETS_DIR

for i in `cat $INDEX`
do

if [ -f $LIGHT_ASSETS_DIR/$i.png ]; then
    echo $LIGHT_ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $LIGHT_ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-filename=$LIGHT_ASSETS_DIR/$i.png $LIGHT_SRC_FILE >/dev/null \
    && $OPTIPNG -o7 --quiet $LIGHT_ASSETS_DIR/$i.png 
fi

if [ -f $DARK_ASSETS_DIR/$i.png ]; then
    echo $DARK_ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $DARK_ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-filename=$DARK_ASSETS_DIR/$i.png $DARK_SRC_FILE >/dev/null \
    && $OPTIPNG -o7 --quiet $DARK_ASSETS_DIR/$i.png 
fi
done

exit 0
