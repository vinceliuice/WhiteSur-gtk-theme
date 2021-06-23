#!/bin/bash

INKSCAPE="$(command -v inkscape)" || true
OPTIPNG="$(command -v optipng)" || true

for theme in 'Monterey' 'WhiteSur'; do
  for screen in '1080p' '2k' '4k'; do
    for color in '-light' '-dark'; do

if [[ "${screen}" == '1080p' ]]; then
  DPI="96"
elif [[ "${screen}" == '2k' ]]; then
  DPI="128"
elif [[ "${screen}" == '4k' ]]; then
  DPI="192"
fi

SRC_FILE="${theme}${color}.svg"
PNG_file="${screen}/${theme}${color}.png"

if [[ -f "$PNG_file" ]]; then
  echo "'$PNG_file' exist! "
else
  echo "Rendering '$PNG_file'"
    "$INKSCAPE" --export-dpi="$DPI" \
                --export-filename="$PNG_file" "$SRC_FILE" >/dev/null

  if [[ -n "${OPTIPNG}" ]]; then
    "$OPTIPNG" -o7 --quiet "$PNG_file"
  fi
fi

    done
  done
done
