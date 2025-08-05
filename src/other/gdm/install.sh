#! /usr/bin/env bash

./parse-sass.sh

./make_gresource.sh

sudo cp -r gnome-shell-theme.gresource /usr/share/gnome-shell/gnome-shell-theme.gresource

