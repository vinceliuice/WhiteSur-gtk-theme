#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

SRC_FILE="assets-light.svg"
DARK_SRC_FILE="assets-dark.svg"
ASSETS_DIR="assets-light"
DARK_ASSETS_DIR="assets-dark"
HDPI_ASSETS_DIR="assets-light-hdpi"
HDPI_DARK_ASSETS_DIR="assets-dark-hdpi"
XHDPI_ASSETS_DIR="assets-light-xhdpi"
XHDPI_DARK_ASSETS_DIR="assets-dark-xhdpi"

INDEX="assets.txt"

#[[ -d $ASSETS_DIR ]] && rm -rf $ASSETS_DIR
#[[ -d $DARK_ASSETS_DIR ]] && rm -rf $DARK_ASSETS_DIR
mkdir -p $ASSETS_DIR && mkdir -p $DARK_ASSETS_DIR
mkdir -p $HDPI_ASSETS_DIR && mkdir -p $HDPI_DARK_ASSETS_DIR
mkdir -p $XHDPI_ASSETS_DIR && mkdir -p $XHDPI_DARK_ASSETS_DIR

for i in `cat $INDEX`
do

# Normal
if [ -f $ASSETS_DIR/$i.png ]; then
    echo $ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-filename=$ASSETS_DIR/$i.png $SRC_FILE >/dev/null \
    && $OPTIPNG -o7 --quiet $ASSETS_DIR/$i.png 
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

# HDPI
if [ -f $HDPI_ASSETS_DIR/$i.png ]; then
    echo $HDPI_ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $HDPI_ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-dpi=144 \
              --export-filename=$HDPI_ASSETS_DIR/$i.png $SRC_FILE >/dev/null \
    && $OPTIPNG -o7 --quiet $HDPI_ASSETS_DIR/$i.png 
fi
if [ -f $HDPI_DARK_ASSETS_DIR/$i.png ]; then
    echo $HDPI_DARK_ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $HDPI_DARK_ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-dpi=144 \
              --export-filename=$HDPI_DARK_ASSETS_DIR/$i.png $DARK_SRC_FILE >/dev/null \
    && $OPTIPNG -o7 --quiet $HDPI_DARK_ASSETS_DIR/$i.png 
fi

# XHDPI
if [ -f $XHDPI_ASSETS_DIR/$i.png ]; then
    echo $XHDPI_ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $XHDPI_ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-dpi=192 \
              --export-filename=$XHDPI_ASSETS_DIR/$i.png $SRC_FILE >/dev/null \
    && $OPTIPNG -o7 --quiet $XHDPI_ASSETS_DIR/$i.png 
fi
if [ -f $XHDPI_DARK_ASSETS_DIR/$i.png ]; then
    echo $XHDPI_DARK_ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $XHDPI_DARK_ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-dpi=192 \
              --export-filename=$XHDPI_DARK_ASSETS_DIR/$i.png $DARK_SRC_FILE >/dev/null \
    && $OPTIPNG -o7 --quiet $XHDPI_DARK_ASSETS_DIR/$i.png 
fi
done
exit 0
