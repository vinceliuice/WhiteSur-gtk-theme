# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

[[ -n "$PAKITHEME_VERBOSE" ]] && set -x ||:

die() {
  echo "$@" >&2
  exit 1
}

pakitheme() {
  local color="$(destify ${1})"
  local opacity="$(destify ${2})"
  local alt="$(destify ${3})"
  local theme="$(destify ${4})"

  local FLATPAK_THEME="${name}${color}${opacity}${alt}${theme}"

  local GTK_THEME_VER=3.22
  local cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local pakitheme_cache="$cache_home/pakitheme"
  local repo_dir="$pakitheme_cache/repo"
  local app_id="org.gtk.Gtk3theme.$FLATPAK_THEME"
  local root_dir="$pakitheme_cache/$FLATPAK_THEME"
  local repo_dir="$root_dir/repo"
  local build_dir="$root_dir/build"

  prompt -i "Converting theme: $FLATPAK_THEME"

  for location in "$data_home/themes" "$HOME/.themes" /usr/share/themes; do
    if [[ -d "$location/$FLATPAK_THEME" ]]; then
      prompt -s "Found theme located at: $location/$FLATPAK_THEME"
      theme_path="$location/$FLATPAK_THEME"
      break
    fi
  done

  [[ -n "$theme_path" ]] || die 'Could not locate theme.'

  rm -rf "$root_dir" "$repo_dir"
  mkdir -p "$repo_dir"
  ostree --repo="$repo_dir" init --mode=archive
  ostree --repo="$repo_dir" config set core.min-free-space-percent 0

  rm -rf "$build_dir"
  mkdir -p "$build_dir/files"

  theme_gtk_version=$(ls -1d "$theme_path"/* 2>/dev/null | grep -Po 'gtk-3\.\K\d+$' | sort -nr | head -1)
  [[ -n "$theme_gtk_version" ]] || \
    die "Theme directory did not contain any recognized GTK themes."

  cp -a "$theme_path/gtk-3.$theme_gtk_version/"* "$build_dir/files"

  mkdir -p "$build_dir/files/share/appdata"
  cat >"$build_dir/files/share/appdata/$app_id.appdata.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="runtime">
  <id>$app_id</id>
  <metadata_license>CC0-1.0</metadata_license>
  <name>$flatpak_name Gtk theme</name>
  <summary>$flatpak_name Gtk theme (generated via pakitheme)</summary>
</component>
EOF

  appstream-compose --prefix="$build_dir/files" --basename="$app_id" --origin=flatpak "$app_id"

  ostree --repo="$repo_dir" commit -b base --tree=dir="$build_dir"

  bundles=()

  while read -r arch; do
    bundle="$root_dir/$app_id-$arch.flatpak"

    rm -rf "$build_dir"
    ostree --repo="$repo_dir" checkout -U base "$build_dir"

    read -rd '' metadata <<EOF ||:
[Runtime]
name=$app_id
runtime=$app_id/$arch/$GTK_THEME_VER
sdk=$app_id/$arch/$GTK_THEME_VER
EOF
    # Make sure there is no trailing newline, so xa.metadata doesn't get confused later
    echo -n "$metadata" > "$build_dir/metadata"

    ostree --repo="$repo_dir" commit -b "runtime/$app_id/$arch/$GTK_THEME_VER" \
      --add-metadata-string "xa.metadata=$(cat $build_dir/metadata)" --link-checkout-speedup "$build_dir"
    flatpak build-bundle --runtime "$repo_dir" "$bundle" "$app_id" "$GTK_THEME_VER"

    trap 'rm "$bundle"' EXIT

    bundles+=("$bundle")
    # Note: a pipe can't be used because it will mess with subshells and cause the append
    # to bundles to fail.
  done < <(flatpak list --runtime --columns=arch:f | sort -u)

  for bundle in "${bundles[@]}"; do
    flatpak install -y --$install_target "${bundle}"
  done
}
