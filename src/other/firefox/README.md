
## <p align="center"> <b> Firefox Safari theme </b> </p>
![01](https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/firefox.png?raw=true)
<p align="center">A MacOSX Safari theme for Firefox 80+</p>

## Description

This is a bunch of CSS code to make Firefox look closer to MacOSX Safari theme.
Based on https://github.com/rafaelmardojai/firefox-gnome-theme

## Installation

Run `./tweaks.sh -f`

if you want to use `Monterey` style then:

Run `./tweaks.sh -f monterey`

### Tips about monterey options (Fix the urlbar attached tabs issue)

1. Remove all space separators on left of urlbar
2. Make sure how many buttons you put on side of urlbar an then run `./tweaks.sh -f monterey -e`

```
/*--------------Configure your Monterey theme--------------
 * ONLY for Monterey theme
 * Enable one of these options and disable the other ones.
 */

/* How many buttons on left headerbar */
@import "Monterey/left_header_button_3.css"; /**/
/*@import "Monterey/left_header_button_4.css"; /**/
/*@import "Monterey/left_header_button_5.css"; /**/

/* How many buttons on right headerbar */
@import "Monterey/right_header_button_3.css"; /**/
/*@import "Monterey/right_header_button_4.css"; /**/
/*@import "Monterey/right_header_button_5.css"; /**/

```

3. Choose the right buttons number config then remove '/*' to enable it and add '/*' to disbale the default one

### Manual installation

1. Go to `about:support` in Firefox.
2. Application Basics > Profile Directory > Open Directory.
3. Copy `chrome` folder Firefox config folder.
4. If you are using Firefox 69+:
	1. Go to `about:config` in Firefox.
	2. Search for `toolkit.legacyUserProfileCustomizations.stylesheets` and set it to `true`.
5. Restart Firefox.
6. Open Firefox customization panel and:
	1. Use *Title bar* option to toggle CSD if is not set by default.
	2. Move the new tab button to headerbar.
	3. Select light or dark variants on theme switcher.
7. Be happy with your new gnomish Firefox.

## Enabling optional features
Open `userChrome.css` with a text editor and follow instructions to enable extra features. Keep in mind this file might change in future versions and your configuration will be lost. You can copy the @imports you want to enable to a new file named `customChrome` directly in your `chrome` directory if you want it to survive updates. Remember all @imports must be at the top of the file, before other statements.

## Known bugs

### CSD have sharp corners
See upstream [bug](https://bugzilla.mozilla.org/show_bug.cgi?id=1408360).

#### Wayland fix:
1. Go to the `about:config` page
2. Search for the `layers.acceleration.force-enabled` preference and set it to true.
3. Now restart Firefox, and it should look good!

#### X11 fix:
1. Go to the `about:config` page
2. Type `mozilla.widget.use-argb-visuals`
3. Set it as a `boolean` and click on the add button
4. Now restart Firefox, and it should look good!

## Development

If you wanna mess around the styles and change something, you might find these
things useful.

To use the Inspector to debug the UI, open the developer tools (F12) on any
page, go to options, check both of those:

- Enable browser chrome and add-on debugging toolboxes
- Enable remote debugging

Now you can close those tools and press Ctrl+Alt+Shift+I to Inspect the browser
UI.
