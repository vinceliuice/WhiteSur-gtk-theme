#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

INDEX="assets.txt"
INDEX_T="theme_assets.txt"

for theme in '' '-blue' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-grey'; do
  ASSETS_DIR="assets${theme}"
  SRC_FILE="assets${theme}.svg"

  [[ -d $ASSETS_DIR ]] && rm -rf $ASSETS_DIR
  mkdir -p $ASSETS_DIR

  if [[ ${theme} == '' ]]; then
    for i in `cat $INDEX`; do
      if [ -f $ASSETS_DIR/$i.png ]; then
        echo $ASSETS_DIR/$i.png exists.
      else
        echo
        echo Rendering $ASSETS_DIR/$i.png
        $INKSCAPE --export-id=$i \
                  --export-id-only \
                  --export-filename=$ASSETS_DIR/$i.png $SRC_FILE >/dev/null
        $OPTIPNG -o7 --quiet $ASSETS_DIR/$i.png 
    fi

    if [ -f $ASSETS_DIR/$i@2.png ]; then
      echo $ASSETS_DIR/$i@2.png exists.
    else
      echo
      echo Rendering $ASSETS_DIR/$i@2.png
      $INKSCAPE --export-id=$i \
                --export-dpi=192 \
                --export-id-only \
                --export-filename=$ASSETS_DIR/$i@2.png $SRC_FILE >/dev/null
      $OPTIPNG -o7 --quiet $ASSETS_DIR/$i@2.png 
    fi
    done
  else
    for i in `cat $INDEX_T`; do
      if [ -f $ASSETS_DIR/$i.png ]; then
        echo $ASSETS_DIR/$i.png exists.
      else
        echo
        echo Rendering $ASSETS_DIR/$i.png
        $INKSCAPE --export-id=$i \
                  --export-id-only \
                  --export-filename=$ASSETS_DIR/$i.png $SRC_FILE >/dev/null
        $OPTIPNG -o7 --quiet $ASSETS_DIR/$i.png 
      fi

      if [ -f $ASSETS_DIR/$i@2.png ]; then
        echo $ASSETS_DIR/$i@2.png exists.
      else
        echo
        echo Rendering $ASSETS_DIR/$i@2.png
        $INKSCAPE --export-id=$i \
                  --export-dpi=192 \
                  --export-id-only \
                  --export-filename=$ASSETS_DIR/$i@2.png $SRC_FILE >/dev/null
        $OPTIPNG -o7 --quiet $ASSETS_DIR/$i@2.png 
      fi
    done
  fi
done

exit 0
