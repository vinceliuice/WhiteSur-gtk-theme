# WhiteSur GTK theme

## Summary

To be able to use the latest/adequate version of sass, install sassc.

## How to tweak the theme

WhiteSur (highly infuenced by Adwaita) is a complex theme, so to keep it maintainable, it's written
and processed in SASS. The generated CSS is then transformed into a gresource file during gtk build
and used at runtime in a non-legible or editable form.

It is very likely your change will happen in the _common.scss file. That's where all the widget
selectors are defined. Here's a rundown of the "supporting" stylesheets, that are unlikely to be the
right place for a drive by stylesheet fix:

_colors.scss        - global color definitions. We keep the number of defined colors to a necessary minimum,
                      most colors are derived from a handful of basics. It covers both the light variant and
                      the dark variant.

_colors-public.scss - SCSS colors exported through gtk to allow for 3rd party apps color mixing.

_drawing.scss       - drawing helper mixings/functions to allow easier definition of widget drawing under
                      specific context. This is why Adwaita isn't 15000 LOC.

_common.scss        - actual definitions of style for each widget. This is where you are likely to add/remove
                      your changes.

You can read about SASS at http://sass-lang.com/documentation/. Once you make your changes to the
_common.scss file, you can either run the ./parse-sass.sh script or keep SASS watching for changes as you
edit.

## Known bugs

### Theme glitches on NVIDIA driver
See upstream [bug](https://web.archive.org/web/20210609140801/https://forums.developer.nvidia.com/t/issues-with-icons-gtk-theme-and-other-graphical-components-prior-to-installation-of-nvidia-drivers/38618).

# WhiteSur Firefox theme
A MacOS Big Sur theme for Firefox 70+

## Known bugs

### CSD have sharp corners
See upstream [bug](https://bugzilla.mozilla.org/show_bug.cgi?id=1408360).

### Icons color broken
Icons might appear black where they should be white on some systems. I have no
idea why, but you can adjust them in the `theme/colors/light.css` or
`theme/colors/dark.css` files, look for `--gnome-icons-hack-filter` var and
play with css filters.

## Development

If you wanna mess around the styles and change something, you might find these
things useful.

To use the Inspector to debug the UI, open the developer tools (F12) on any
page, go to options, check both of those:

- Enable browser chrome and add-on debugging toolboxes
- Enable remote debugging

Now you can close those tools and press Ctrl+Alt+Shift+I to Inspect the browser
UI.

Also you can inspect any GTK3 application, for example type this into a terminal
and it will run Epiphany with the GTK Inspector, so you can check the CSS styles
of its elements too.

```sh
GTK_DEBUG=interactive epiphany
```

Feel free to use any parts of my code to develop your own themes, I don't force
any specific license on your code.

## Credits
Developed by **Rafael Mardojai** and [contributors](https://github.com/rafaelmardojai/firefox-gnome-theme/graphs/contributors). Based on **[Sai Kurogetsu](https://github.com/kurogetsusai/firefox-gnome-theme)** original work.

# WhiteSur GDM and GNOME Shell theme

## Known bugs

### Can't change GDM background on OpenSUSE Tumbleweed
See upstream [bug](https://github.com/juhaku/loginized#known-limitations-and-issues).
