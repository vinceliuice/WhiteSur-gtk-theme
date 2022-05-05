#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

./make-thumbnails.sh

for theme in '' '-blue' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-grey'; do
  for type in '' '-nord'; do
    SRC_FILE="thumbnail${theme}${type}.svg"
    for color in '-light' '-dark'; do
            echo
            echo Rendering thumbnail${color}${theme}${type}.png
            $INKSCAPE --export-id=thumbnail${color}${theme}${type} \
                      --export-id-only \
                      --export-dpi=96 \
                      --export-filename=thumbnail${color}${theme}${type}.png $SRC_FILE >/dev/null \
            && $OPTIPNG -o7 --quiet thumbnail${color}${theme}${type}.png
      done
    done
  done

for theme in '' '-blue' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-grey'; do
  for type in '' '-nord'; do
    if [[ ${theme} == '' && ${type} == '' ]]; then
      echo "keep thumbnail.svg"
    else
      rm -rf "thumbnail${theme}${type}.svg"
    fi
  done
done

exit 0
