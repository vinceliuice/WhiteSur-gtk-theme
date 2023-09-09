#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

INDEX="assets.txt"

for i in `cat $INDEX`; do
  for color in '-Dark' '-Light'; do
    for theme in '' '-nord'; do
      for screen in '' '-hdpi' '-xhdpi'; do
        ASSETS_DIR="assets${color}${theme}${screen}"
        SRC_FILE="assets${color}${theme}.svg"

        case "${screen}" in
            -hdpi)
              DPI='144'
              ;;
            -xhdpi)
              DPI='192'
               ;;
            *)
              DPI='96'
              ;;
        esac

        mkdir -p $ASSETS_DIR

        if [ -f $ASSETS_DIR/$i.png ]; then
          echo $ASSETS_DIR/$i.png exists.
        else
          echo
          echo Rendering $ASSETS_DIR/$i.png
          $INKSCAPE --export-id=$i \
                    --export-id-only \
                    --export-dpi=$DPI \
                    --export-filename=$ASSETS_DIR/$i.png $SRC_FILE >/dev/null \
          && $OPTIPNG -o7 --quiet $ASSETS_DIR/$i.png
        fi
      done
    done
  done
done

exit 0
