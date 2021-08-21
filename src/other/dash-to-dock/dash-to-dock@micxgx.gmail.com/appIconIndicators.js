const Cairo = imports.cairo;
const Clutter = imports.gi.Clutter;
const GdkPixbuf = imports.gi.GdkPixbuf
const Gio = imports.gi.Gio;
const Graphene = imports.gi.Graphene;
const Gtk = imports.gi.Gtk;
const Main = imports.ui.main;
const Pango = imports.gi.Pango;
const Shell = imports.gi.Shell;
const St = imports.gi.St;

const Util = imports.misc.util;

const Me = imports.misc.extensionUtils.getCurrentExtension();
const Docking = Me.imports.docking;
const Utils = Me.imports.utils;

let tracker = Shell.WindowTracker.get_default();

const RunningIndicatorStyle = {
    DEFAULT: 0,
    DOTS: 1,
    SQUARES: 2,
    DASHES: 3,
    SEGMENTED: 4,
    SOLID: 5,
    CILIORA: 6,
    METRO: 7
};

const MAX_WINDOWS_CLASSES = 4;


/*
 * This is the main indicator class to be used. The desired bahviour is
 * obtained by composing the desired classes below based on the settings.
 *
 */
var AppIconIndicator = class DashToDock_AppIconIndicator {

    constructor(source) {
        this._indicators = [];

        // Unity indicators always enabled for now
        let unityIndicator = new UnityIndicator(source);
        this._indicators.push(unityIndicator);

        // Choose the style for the running indicators
        let runningIndicator = null;
        let runningIndicatorStyle;

        let settings = Docking.DockManager.settings;
        if (settings.get_boolean('apply-custom-theme' )) {
            runningIndicatorStyle = RunningIndicatorStyle.DOTS;
        } else {
            runningIndicatorStyle = settings.get_enum('running-indicator-style');
        }

        switch (runningIndicatorStyle) {
            case RunningIndicatorStyle.DEFAULT:
                runningIndicator = new RunningIndicatorDefault(source);
                break;

            case RunningIndicatorStyle.DOTS:
                runningIndicator = new RunningIndicatorDots(source);
                break;

            case RunningIndicatorStyle.SQUARES:
                runningIndicator = new RunningIndicatorSquares(source);
                break;

            case RunningIndicatorStyle.DASHES:
                runningIndicator = new RunningIndicatorDashes(source);
            break;

            case RunningIndicatorStyle.SEGMENTED:
                runningIndicator = new RunningIndicatorSegmented(source);
                break;

            case RunningIndicatorStyle.SOLID:
                runningIndicator = new RunningIndicatorSolid(source);
                break;

            case RunningIndicatorStyle.CILIORA:
                runningIndicator = new RunningIndicatorCiliora(source);
                break;

            case RunningIndicatorStyle.METRO:
                runningIndicator = new RunningIndicatorMetro(source);
            break;

            default:
                runningIndicator = new RunningIndicatorBase(source);
        }

        this._indicators.push(runningIndicator);
    }

    update() {
        for (let i=0; i<this._indicators.length; i++){
            let indicator = this._indicators[i];
            indicator.update();
        }
    }

    destroy() {
        for (let i=0; i<this._indicators.length; i++){
            let indicator = this._indicators[i];
            indicator.destroy();
        }
    }
}

/*
 * Base class to be inherited by all indicators of any kind
*/
var IndicatorBase = class DashToDock_IndicatorBase {

    constructor(source) {
        this._source = source;
        this._signalsHandler = new Utils.GlobalSignalsHandler();

        this._sourceDestroyId = this._source.connect('destroy', () => {
            this._signalsHandler.destroy();
        });
    }

    update() {
    }

    destroy() {
        this._source.disconnect(this._sourceDestroyId);
        this._signalsHandler.destroy();
    }
};

/*
 * A base indicator class for running style, from which all other EunningIndicators should derive,
 * providing some basic methods, variables definitions and their update,  css style classes handling.
 *
 */
var RunningIndicatorBase = class DashToDock_RunningIndicatorBase extends IndicatorBase {

    constructor(source) {
        super(source)

        this._side = Utils.getPosition();
        this._nWindows = 0;

        this._dominantColorExtractor = new DominantColorExtractor(this._source.app);

        // These statuses take into account the workspace/monitor isolation
        this._isFocused = false;
        this._isRunning = false;
    }

    update() {
        // Limit to 1 to MAX_WINDOWS_CLASSES  windows classes
        this._nWindows = Math.min(this._source.getInterestingWindows().length, MAX_WINDOWS_CLASSES);

        // We need to check the number of windows, as the focus might be
        // happening on another monitor if using isolation
        if (tracker.focus_app == this._source.app && this._nWindows > 0)
            this._isFocused = true;
        else
            this._isFocused = false;

        // In the case of workspace isolation, we need to hide the dots of apps with
        // no windows in the current workspace
        if ((this._source.app.state != Shell.AppState.STOPPED || this._source.isLocation()) && this._nWindows > 0)
            this._isRunning = true;
        else
            this._isRunning = false;

        this._updateCounterClass();
        this._updateFocusClass();
        this._updateDefaultDot();
    }

    _updateCounterClass() {
        for (let i = 1; i <= MAX_WINDOWS_CLASSES; i++) {
            let className = 'running' + i;
            if (i != this._nWindows)
                this._source.remove_style_class_name(className);
            else
                this._source.add_style_class_name(className);
        }
    }

    _updateFocusClass() {
        if (this._isFocused)
            this._source.add_style_class_name('focused');
        else
            this._source.remove_style_class_name('focused');
    }

    _updateDefaultDot() {
        if (this._isRunning)
            this._source._dot.show();
        else
            this._source._dot.hide();
    }

    _hideDefaultDot() {
        // I use opacity to hide the default dot because the show/hide function
        // are used by the parent class.
        this._source._dot.opacity = 0;
    }

    _restoreDefaultDot() {
        this._source._dot.opacity = 255;
    }

    _enableBacklight() {

        let colorPalette = this._dominantColorExtractor._getColorPalette();

        // Fallback
        if (colorPalette === null) {
            this._source._iconContainer.set_style(
                'border-radius: 5px;' +
                'background-gradient-direction: vertical;' +
                'background-gradient-start: #e0e0e0;' +
                'background-gradient-end: darkgray;'
            );

           return;
        }

        this._source._iconContainer.set_style(
            'border-radius: 5px;' +
            'background-gradient-direction: vertical;' +
            'background-gradient-start: ' + colorPalette.original + ';' +
            'background-gradient-end: ' +  colorPalette.darker + ';'
        );

    }

    _disableBacklight() {
        this._source._iconContainer.set_style(null);
    }

    destroy() {
        this._disableBacklight();
        // Remove glossy background if the children still exists
        if (this._source._iconContainer.get_children().length > 1)
            this._source._iconContainer.get_children()[1].set_style(null);
        this._restoreDefaultDot();

        super.destroy();
    }
};

// We add a css class so third parties themes can limit their indicaor customization
// to the case we do nothing
var RunningIndicatorDefault = class DashToDock_RunningIndicatorDefault extends RunningIndicatorBase {

    constructor(source) {
        super(source);
        this._source.add_style_class_name('default');
    }

    destroy() {
        this._source.remove_style_class_name('default');
        super.destroy();
    }
};

var RunningIndicatorDots = class DashToDock_RunningIndicatorDots extends RunningIndicatorBase {

    constructor(source) {
        super(source)

        this._hideDefaultDot();

        this._area = new St.DrawingArea({x_expand: true, y_expand: true});

        // We draw for the bottom case and rotate the canvas for other placements
        //set center of rotatoins to the center
        this._area.set_pivot_point(0.5, 0.5);
        // prepare transformation matrix
        let m = new Graphene.Matrix();
        m.init_identity();
        let v = new Graphene.Vec3();
        v.init(0, 0, 1);

        switch (this._side) {
        case St.Side.TOP:
            m.xx = -1; 
            m.rotate(180, v);
            break

        case St.Side.BOTTOM:
            // nothing
            break;

        case St.Side.LEFT:
            m.yy = -1;
            m.rotate(90, v);
            break;

        case St.Side.RIGHT:
            m.rotate(-90, v);
            break
        }

        this._area.set_transform(m);

        this._area.connect('repaint', this._updateIndicator.bind(this));
        this._source._iconContainer.add_child(this._area);

        let keys = ['custom-theme-running-dots-color',
                   'custom-theme-running-dots-border-color',
                   'custom-theme-running-dots-border-width',
                   'custom-theme-customize-running-dots',
                   'unity-backlit-items',
                   'running-indicator-dominant-color'];

        keys.forEach(function(key) {
            this._signalsHandler.add([
                Docking.DockManager.settings,
                'changed::' + key,
                this.update.bind(this)
            ]);
        }, this);

        // Apply glossy background
        // TODO: move to enable/disableBacklit to apply itonly to the running apps?
        // TODO: move to css class for theming support
        this._glossyBackgroundStyle = 'background-image: url(\'' + Me.path + '/media/glossy.svg\');' +
                                      'background-size: contain;';
    }

    update() {
        super.update();

        // Enable / Disable the backlight of running apps
        if (!Docking.DockManager.settings.get_boolean('apply-custom-theme') &&
            Docking.DockManager.settings.get_boolean('unity-backlit-items')) {
            this._source._iconContainer.get_children()[1].set_style(this._glossyBackgroundStyle);
            if (this._isRunning)
                this._enableBacklight();
            else
                this._disableBacklight();
        } else {
            this._disableBacklight();
            this._source._iconContainer.get_children()[1].set_style(null);
        }

        if (this._area)
            this._area.queue_repaint();
    }

     _computeStyle() {

        let [width, height] = this._area.get_surface_size();
        this._width = height;
        this._height = width;

        // By defaut re-use the style - background color, and border width and color -
        // of the default dot
        let themeNode = this._source._dot.get_theme_node();
        this._borderColor = themeNode.get_border_color(this._side);
        this._borderWidth = themeNode.get_border_width(this._side);
        this._bodyColor = themeNode.get_background_color();

        let settings = Docking.DockManager.settings;
        if (!settings.get_boolean('apply-custom-theme')) {
            // Adjust for the backlit case
            if (settings.get_boolean('unity-backlit-items')) {
                // Use dominant color for dots too if the backlit is enables
                let colorPalette = this._dominantColorExtractor._getColorPalette();

                // Slightly adjust the styling
                this._borderWidth = 2;

                if (colorPalette !== null) {
                    this._borderColor = Clutter.color_from_string(colorPalette.lighter)[1] ;
                    this._bodyColor = Clutter.color_from_string(colorPalette.darker)[1];
                } else {
                    // Fallback
                    this._borderColor = Clutter.color_from_string('white')[1];
                    this._bodyColor = Clutter.color_from_string('gray')[1];
                }
            }

            // Apply dominant color if requested
            if (settings.get_boolean('running-indicator-dominant-color')) {
                let colorPalette = this._dominantColorExtractor._getColorPalette();
                if (colorPalette !== null) {
                    this._bodyColor = Clutter.color_from_string(colorPalette.original)[1];
                }
            }

            // Finally, use customize style if requested
            if (settings.get_boolean('custom-theme-customize-running-dots')) {
                this._borderColor = Clutter.color_from_string(settings.get_string('custom-theme-running-dots-border-color'))[1];
                this._borderWidth = settings.get_int('custom-theme-running-dots-border-width');
                this._bodyColor =  Clutter.color_from_string(settings.get_string('custom-theme-running-dots-color'))[1];
            }
        }

        // Define the radius as an arbitrary size, but keep large enough to account
        // for the drawing of the border.
        this._radius = Math.max(this._width/22, this._borderWidth/2);
        this._padding = 0; // distance from the margin
        this._spacing = this._radius + this._borderWidth; // separation between the dots
     }

    _updateIndicator() {

        let area = this._area;
        let cr = this._area.get_context();

        this._computeStyle();
        this._drawIndicator(cr);
        cr.$dispose();
    }

    _drawIndicator(cr) {
        // Draw the required numbers of dots
        let n = this._nWindows;

        cr.setLineWidth(this._borderWidth);
        Clutter.cairo_set_source_color(cr, this._borderColor);

        // draw for the bottom case:
        cr.translate((this._width - (2*n)*this._radius - (n-1)*this._spacing)/2, this._height - this._padding);
        for (let i = 0; i < n; i++) {
            cr.newSubPath();
            cr.arc((2*i+1)*this._radius + i*this._spacing, -this._radius - this._borderWidth/2, this._radius, 0, 2*Math.PI);
        }

        cr.strokePreserve();
        Clutter.cairo_set_source_color(cr, this._bodyColor);
        cr.fill();
    }

    destroy() {
        this._area.destroy();
        super.destroy();
    }
};

// Adapted from dash-to-panel by Jason DeRose
// https://github.com/jderose9/dash-to-panel
var RunningIndicatorCiliora = class DashToDock_RunningIndicatorCiliora extends RunningIndicatorDots {

    _drawIndicator(cr) {
        if (this._isRunning) {

            let size =  Math.max(this._width/20, this._borderWidth);
            let spacing = size; // separation between the dots
            let lineLength = this._width - (size*(this._nWindows-1)) - (spacing*(this._nWindows-1));
            let padding = this._borderWidth;
            // For the backlit case here we don't want the outer border visible
            if (Docking.DockManager.settings.get_boolean('unity-backlit-items') &&
                !Docking.DockManager.settings.get_boolean('custom-theme-customize-running-dots'))
                padding = 0;
            let yOffset = this._height - padding - size;

            cr.setLineWidth(this._borderWidth);
            Clutter.cairo_set_source_color(cr, this._borderColor);

            cr.translate(0, yOffset);
            cr.newSubPath();
            cr.rectangle(0, 0, lineLength, size);
            for (let i = 1; i < this._nWindows; i++) {
                cr.newSubPath();
                cr.rectangle(lineLength + (i*spacing) + ((i-1)*size), 0, size, size);
            }

            cr.strokePreserve();
            Clutter.cairo_set_source_color(cr, this._bodyColor);
            cr.fill();
        }
    }
};

// Adapted from dash-to-panel by Jason DeRose
// https://github.com/jderose9/dash-to-panel
var RunningIndicatorSegmented = class DashToDock_RunningIndicatorSegmented extends RunningIndicatorDots {

    _drawIndicator(cr) {
        if (this._isRunning) {
            let size =  Math.max(this._width/20, this._borderWidth);
            let spacing = Math.ceil(this._width/18); // separation between the dots
            let dashLength = Math.ceil((this._width - ((this._nWindows-1)*spacing))/this._nWindows);
            let lineLength = this._width - (size*(this._nWindows-1)) - (spacing*(this._nWindows-1));
            let padding = this._borderWidth;
            // For the backlit case here we don't want the outer border visible
            if (Docking.DockManager.settings.get_boolean('unity-backlit-items') &&
                !Docking.DockManager.settings.get_boolean('custom-theme-customize-running-dots'))
                padding = 0;
            let yOffset = this._height - padding - size;

            cr.setLineWidth(this._borderWidth);
            Clutter.cairo_set_source_color(cr, this._borderColor);

            cr.translate(0, yOffset);
            for (let i = 0; i < this._nWindows; i++) {
                cr.newSubPath();
                cr.rectangle(i*dashLength + i*spacing, 0, dashLength, size);
            }

            cr.strokePreserve();
            Clutter.cairo_set_source_color(cr, this._bodyColor);
            cr.fill()
        }
    }
};

// Adapted from dash-to-panel by Jason DeRose
// https://github.com/jderose9/dash-to-panel
var RunningIndicatorSolid = class DashToDock_RunningIndicatorSolid extends RunningIndicatorDots {

    _drawIndicator(cr) {
        if (this._isRunning) {

            let size =  Math.max(this._width/20, this._borderWidth);
            let padding = this._borderWidth;
            // For the backlit case here we don't want the outer border visible
            if (Docking.DockManager.settings.get_boolean('unity-backlit-items') &&
                !Docking.DockManager.settings.get_boolean('custom-theme-customize-running-dots'))
                padding = 0;
            let yOffset = this._height - padding - size;

            cr.setLineWidth(this._borderWidth);
            Clutter.cairo_set_source_color(cr, this._borderColor);

            cr.translate(0, yOffset);
            cr.newSubPath();
            cr.rectangle(0, 0, this._width, size);

            cr.strokePreserve();
            Clutter.cairo_set_source_color(cr, this._bodyColor);
            cr.fill();

        }
    }
};

// Adapted from dash-to-panel by Jason DeRose
// https://github.com/jderose9/dash-to-panel
var RunningIndicatorSquares = class DashToDock_RunningIndicatorSquares extends RunningIndicatorDots {

    _drawIndicator(cr) {
        if (this._isRunning) {
            let size =  Math.max(this._width/11, this._borderWidth);
            let padding = this._borderWidth;
            let spacing = Math.ceil(this._width/18); // separation between the dots
            let yOffset = this._height - padding - size;

            cr.setLineWidth(this._borderWidth);
            Clutter.cairo_set_source_color(cr, this._borderColor);

            cr.translate(Math.floor((this._width - this._nWindows*size - (this._nWindows-1)*spacing)/2), yOffset);
            for (let i = 0; i < this._nWindows; i++) {
                cr.newSubPath();
                cr.rectangle(i*size + i*spacing, 0, size, size);
            }
            cr.strokePreserve();
            Clutter.cairo_set_source_color(cr, this._bodyColor);
            cr.fill();
        }
    }
}

// Adapted from dash-to-panel by Jason DeRose
// https://github.com/jderose9/dash-to-panel
var RunningIndicatorDashes = class DashToDock_RunningIndicatorDashes extends RunningIndicatorDots {

    _drawIndicator(cr) {
        if (this._isRunning) {
            let size =  Math.max(this._width/20, this._borderWidth);
            let padding = this._borderWidth;
            let spacing = Math.ceil(this._width/18); // separation between the dots
            let dashLength = Math.floor(this._width/4) - spacing;
            let yOffset = this._height - padding - size;

            cr.setLineWidth(this._borderWidth);
            Clutter.cairo_set_source_color(cr, this._borderColor);

            cr.translate(Math.floor((this._width - this._nWindows*dashLength - (this._nWindows-1)*spacing)/2), yOffset);
            for (let i = 0; i < this._nWindows; i++) {
                cr.newSubPath();
                cr.rectangle(i*dashLength + i*spacing, 0, dashLength, size);
            }

            cr.strokePreserve();
            Clutter.cairo_set_source_color(cr, this._bodyColor);
            cr.fill();
        }
    }
}

// Adapted from dash-to-panel by Jason DeRose
// https://github.com/jderose9/dash-to-panel
var RunningIndicatorMetro = class DashToDock_RunningIndicatorMetro extends RunningIndicatorDots {

    constructor(source) {
        super(source);
        this._source.add_style_class_name('metro');
    }

    destroy() {
        this._source.remove_style_class_name('metro');
        super.destroy();
    }

    _drawIndicator(cr) {
        if (this._isRunning) {
            let size =  Math.max(this._width/20, this._borderWidth);
            let padding = 0;
            // For the backlit case here we don't want the outer border visible
            if (Docking.DockManager.settings.get_boolean('unity-backlit-items') &&
                !Docking.DockManager.settings.get_boolean('custom-theme-customize-running-dots'))
                padding = 0;
            let yOffset = this._height - padding - size;

            let n = this._nWindows;
            if(n <= 1) {
                cr.translate(0, yOffset);
                Clutter.cairo_set_source_color(cr, this._bodyColor);
                cr.newSubPath();
                cr.rectangle(0, 0, this._width, size);
                cr.fill();
            } else {
                let blackenedLength = (1/48)*this._width; // need to scale with the SVG for the stacked highlight
                let darkenedLength = this._isFocused ? (2/48)*this._width : (10/48)*this._width;
                let blackenedColor = this._bodyColor.shade(.3);
                let darkenedColor = this._bodyColor.shade(.7);

                cr.translate(0, yOffset);

                Clutter.cairo_set_source_color(cr, this._bodyColor);
                cr.newSubPath();
                cr.rectangle(0, 0, this._width - darkenedLength - blackenedLength, size);
                cr.fill();
                Clutter.cairo_set_source_color(cr, blackenedColor);
                cr.newSubPath();
                cr.rectangle(this._width - darkenedLength - blackenedLength, 0, 1, size);
                cr.fill();
                Clutter.cairo_set_source_color(cr, darkenedColor);
                cr.newSubPath();
                cr.rectangle(this._width - darkenedLength, 0, darkenedLength, size);
                cr.fill();
            }
        }
    }
}

/*
 * Unity like notification and progress indicators
 */
var UnityIndicator = class DashToDock_UnityIndicator extends IndicatorBase {

    constructor(source) {

        super(source);

        this._notificationBadgeLabel = new St.Label();
        this._notificationBadgeBin = new St.Bin({
            child: this._notificationBadgeLabel,
            x_align: Clutter.ActorAlign.END,
            y_align: Clutter.ActorAlign.START,
            x_expand: true, y_expand: true
        });
        this._notificationBadgeLabel.add_style_class_name('notification-badge');
        this._notificationBadgeLabel.clutter_text.ellipsize = Pango.EllipsizeMode.MIDDLE;
        this._notificationBadgeBin.hide();

        this._source._iconContainer.add_child(this._notificationBadgeBin);
        this.updateNotificationBadgeStyle();

        const remoteEntry = this._source.remoteModel.lookupById(this._source.app.id);
        this._signalsHandler.add([
            remoteEntry,
            ['count-changed', 'count-visible-changed'],
            (sender, { count, count_visible }) =>
                this.setNotificationCount(count_visible ? count : 0)
        ], [
            remoteEntry,
            ['progress-changed', 'progress-visible-changed'],
            (sender, { progress, progress_visible }) =>
                this.setProgress(progress_visible ? progress : -1)
        ], [
            remoteEntry,
            'urgent-changed',
            (sender, { urgent }) => this.setUrgent(urgent)
        ], [
            St.ThemeContext.get_for_stage(global.stage),
            'changed',
            this.updateNotificationBadgeStyle.bind(this)
        ], [
            this._source._iconContainer,
            'notify::size',
            this.updateNotificationBadgeStyle.bind(this)
        ]);

        this._isUrgent = false;
    }

    updateNotificationBadgeStyle() {
        let themeContext = St.ThemeContext.get_for_stage(global.stage);
        let fontDesc = themeContext.get_font();
        let defaultFontSize = fontDesc.get_size() / 1024;
        let fontSize = defaultFontSize * 0.9;
        let iconSize = Main.overview.dash.iconSize;
        let defaultIconSize = Docking.DockManager.settings.get_default_value(
            'dash-max-icon-size').unpack();

        if (!fontDesc.get_size_is_absolute()) {
            // fontSize was exprimed in points, so convert to pixel
            fontSize /= 0.75;
        }

        fontSize = Math.round((iconSize / defaultIconSize) * fontSize);
        let leftMargin = Math.round((iconSize / defaultIconSize) * 3);

        this._notificationBadgeLabel.set_style(
            'font-size: ' + fontSize + 'px;' +
            'margin-left: ' + leftMargin + 'px'
        );
    }

    _notificationBadgeCountToText(count) {
        if (count <= 9999) {
            return count.toString();
        } else if (count < 1e5) {
            let thousands = count / 1e3;
            return thousands.toFixed(1).toString() + "k";
        } else if (count < 1e6) {
            let thousands = count / 1e3;
            return thousands.toFixed(0).toString() + "k";
        } else if (count < 1e8) {
            let millions = count / 1e6;
            return millions.toFixed(1).toString() + "M";
        } else if (count < 1e9) {
            let millions = count / 1e6;
            return millions.toFixed(0).toString() + "M";
        } else {
            let billions = count / 1e9;
            return billions.toFixed(1).toString() + "B";
        }
    }

    setNotificationCount(count) {
        if (count > 0) {
            let text = this._notificationBadgeCountToText(count);
            this._notificationBadgeLabel.set_text(text);
            this._notificationBadgeBin.show();
        } else {
            this._notificationBadgeBin.hide();
        }
    }

    _showProgressOverlay() {
        if (this._progressOverlayArea) {
            this._updateProgressOverlay();
            return;
        }

        this._progressOverlayArea = new St.DrawingArea({x_expand: true, y_expand: true});
        this._progressOverlayArea.add_style_class_name('progress-bar');
        this._progressOverlayArea.connect('repaint', () => {
            this._drawProgressOverlay(this._progressOverlayArea);
        });

        this._source._iconContainer.add_child(this._progressOverlayArea);
        let node = this._progressOverlayArea.get_theme_node();

        let [hasColor, color] = node.lookup_color('-progress-bar-background', false);
        if (hasColor)
            this._progressbar_background = color
        else
            this._progressbar_background = new Clutter.Color({red: 204, green: 204, blue: 204, alpha: 255});

        [hasColor, color] = node.lookup_color('-progress-bar-border', false);
        if (hasColor)
            this._progressbar_border = color;
        else
            this._progressbar_border = new Clutter.Color({red: 230, green: 230, blue: 230, alpha: 255});

        this._updateProgressOverlay();
    }

    _hideProgressOverlay() {
        if (this._progressOverlayArea)
            this._progressOverlayArea.destroy();
        this._progressOverlayArea = null;
        this._progressbar_background = null;
        this._progressbar_border = null;
    }

    _updateProgressOverlay() {
        if (this._progressOverlayArea)
            this._progressOverlayArea.queue_repaint();
    }

    _drawProgressOverlay(area) {
        let scaleFactor = St.ThemeContext.get_for_stage(global.stage).scale_factor;
        let [surfaceWidth, surfaceHeight] = area.get_surface_size();
        let cr = area.get_context();

        let iconSize = this._source.icon.iconSize * scaleFactor;

        let x = Math.floor((surfaceWidth - iconSize) / 2);
        let y = Math.floor((surfaceHeight - iconSize) / 2);

        let lineWidth = Math.floor(1.0 * scaleFactor);
        let padding = Math.floor(iconSize * 0.05);
        let width = iconSize - 2.0*padding;
        let height = Math.floor(Math.min(18.0*scaleFactor, 0.20*iconSize));
        x += padding;
        y += iconSize - height - padding;

        cr.setLineWidth(lineWidth);

        // Draw the outer stroke
        let stroke = new Cairo.LinearGradient(0, y, 0, y + height);
        let fill = null;
        stroke.addColorStopRGBA(0.5, 0.5, 0.5, 0.5, 0.1);
        stroke.addColorStopRGBA(0.9, 0.8, 0.8, 0.8, 0.4);
        Utils.drawRoundedLine(cr, x + lineWidth/2.0, y + lineWidth/2.0, width, height, true, true, stroke, fill);

        // Draw the background
        x += lineWidth;
        y += lineWidth;
        width -= 2.0*lineWidth;
        height -= 2.0*lineWidth;

        stroke = Cairo.SolidPattern.createRGBA(0.20, 0.20, 0.20, 0.9);
        fill = new Cairo.LinearGradient(0, y, 0, y + height);
        fill.addColorStopRGBA(0.4, 0.25, 0.25, 0.25, 1.0);
        fill.addColorStopRGBA(0.9, 0.35, 0.35, 0.35, 1.0);
        Utils.drawRoundedLine(cr, x + lineWidth/2.0, y + lineWidth/2.0, width, height, true, true, stroke, fill);

        // Draw the finished bar
        x += lineWidth;
        y += lineWidth;
        width -= 2.0*lineWidth;
        height -= 2.0*lineWidth;

        let finishedWidth = Math.ceil(this._progress * width);

        let bg = this._progressbar_background;
        let bd = this._progressbar_border;

        stroke = Cairo.SolidPattern.createRGBA(bd.red/255, bd.green/255, bd.blue/255, bd.alpha/255);
        fill = Cairo.SolidPattern.createRGBA(bg.red/255, bg.green/255, bg.blue/255, bg.alpha/255);

        if (Clutter.get_default_text_direction() == Clutter.TextDirection.RTL)
            Utils.drawRoundedLine(cr, x + lineWidth/2.0 + width - finishedWidth, y + lineWidth/2.0, finishedWidth, height, true, true, stroke, fill);
        else
            Utils.drawRoundedLine(cr, x + lineWidth/2.0, y + lineWidth/2.0, finishedWidth, height, true, true, stroke, fill);

        cr.$dispose();
    }

    setProgress(progress) {
        if (progress < 0) {
            this._hideProgressOverlay();
        } else {
            this._progress = Math.min(progress, 1.0);
            this._showProgressOverlay();
        }
    }

    setUrgent(urgent) {
        const icon = this._source.icon._iconBin;
        if (urgent) {
            if (!this._isUrgent) {
                icon.set_pivot_point(0.5, 0.5);
                this._source.iconAnimator.addAnimation(icon, 'dance');
                this._isUrgent = true;
            }
        } else {
            if (this._isUrgent) {
                this._source.iconAnimator.removeAnimation(icon, 'dance');
                this._isUrgent = false;
            }
            icon.rotation_angle_z = 0;
        }
    }
}


// We need an icons theme object, this is the only way I managed to get
// pixel buffers that can be used for calculating the backlight color
let themeLoader = null;

// Global icon cache. Used for Unity7 styling.
let iconCacheMap = new Map();
// Max number of items to store
// We don't expect to ever reach this number, but let's put an hard limit to avoid
// even the remote possibility of the cached items to grow indefinitely.
const MAX_CACHED_ITEMS = 1000;
// When the size exceed it, the oldest 'n' ones are deleted
const  BATCH_SIZE_TO_DELETE = 50;
// The icon size used to extract the dominant color
const DOMINANT_COLOR_ICON_SIZE = 64;

// Compute dominant color frim the app icon.
// The color is cached for efficiency.
var DominantColorExtractor = class DashToDock_DominantColorExtractor {

    constructor(app) {
        this._app = app;
    }

    /**
     * Try to get the pixel buffer for the current icon, if not fail gracefully
     */
    _getIconPixBuf() {
        let iconTexture = this._app.create_icon_texture(16);

        if (themeLoader === null) {
            let ifaceSettings = new Gio.Settings({ schema: "org.gnome.desktop.interface" });

            themeLoader = new Gtk.IconTheme(),
            themeLoader.set_custom_theme(ifaceSettings.get_string('icon-theme')); // Make sure the correct theme is loaded
        }

        // Unable to load the icon texture, use fallback
        if (iconTexture instanceof St.Icon === false) {
            return null;
        }

        iconTexture = iconTexture.get_gicon();

        // Unable to load the icon texture, use fallback
        if (iconTexture === null) {
            return null;
        }

        if (iconTexture instanceof Gio.FileIcon) {
            // Use GdkPixBuf to load the pixel buffer from the provided file path
            return GdkPixbuf.Pixbuf.new_from_file(iconTexture.get_file().get_path());
        }

        // Get the pixel buffer from the icon theme
        let icon_info = themeLoader.lookup_icon(iconTexture.get_names()[0], DOMINANT_COLOR_ICON_SIZE, 0);
        if (icon_info !== null)
            return icon_info.load_icon();
        else
            return null;
    }

    /**
     * The backlight color choosing algorithm was mostly ported to javascript from the
     * Unity7 C++ source of Canonicals:
     * https://bazaar.launchpad.net/~unity-team/unity/trunk/view/head:/launcher/LauncherIcon.cpp
     * so it more or less works the same way.
     */
    _getColorPalette() {
        if (iconCacheMap.get(this._app.get_id())) {
            // We already know the answer
            return iconCacheMap.get(this._app.get_id());
        }

        let pixBuf = this._getIconPixBuf();
        if (pixBuf == null)
            return null;

        let pixels = pixBuf.get_pixels(),
            offset = 0;

        let total  = 0,
            rTotal = 0,
            gTotal = 0,
            bTotal = 0;

        let resample_y = 1,
            resample_x = 1;

        // Resampling of large icons
        // We resample icons larger than twice the desired size, as the resampling
        // to a size s
        // DOMINANT_COLOR_ICON_SIZE < s < 2*DOMINANT_COLOR_ICON_SIZE,
        // most of the case exactly DOMINANT_COLOR_ICON_SIZE as the icon size is tipycally
        // a multiple of it.
        let width = pixBuf.get_width();
        let height = pixBuf.get_height();

        // Resample
        if (height >= 2* DOMINANT_COLOR_ICON_SIZE)
            resample_y = Math.floor(height/DOMINANT_COLOR_ICON_SIZE);

        if (width >= 2* DOMINANT_COLOR_ICON_SIZE)
            resample_x = Math.floor(width/DOMINANT_COLOR_ICON_SIZE);

        if (resample_x !==1 || resample_y !== 1)
            pixels = this._resamplePixels(pixels, resample_x, resample_y);

        // computing the limit outside the for (where it would be repeated at each iteration)
        // for performance reasons
        let limit = pixels.length;
        for (let offset = 0; offset < limit; offset+=4) {
            let r = pixels[offset],
                g = pixels[offset + 1],
                b = pixels[offset + 2],
                a = pixels[offset + 3];

            let saturation = (Math.max(r,g, b) - Math.min(r,g, b));
            let relevance  = 0.1 * 255 * 255 + 0.9 * a * saturation;

            rTotal += r * relevance;
            gTotal += g * relevance;
            bTotal += b * relevance;

            total += relevance;
        }

        total = total * 255;

        let r = rTotal / total,
            g = gTotal / total,
            b = bTotal / total;

        let hsv = Utils.ColorUtils.RGBtoHSV(r * 255, g * 255, b * 255);

        if (hsv.s > 0.15)
            hsv.s = 0.65;
        hsv.v = 0.90;

        let rgb = Utils.ColorUtils.HSVtoRGB(hsv.h, hsv.s, hsv.v);

        // Cache the result.
        let backgroundColor = {
            lighter:  Utils.ColorUtils.ColorLuminance(rgb.r, rgb.g, rgb.b, 0.2),
            original: Utils.ColorUtils.ColorLuminance(rgb.r, rgb.g, rgb.b, 0),
            darker:   Utils.ColorUtils.ColorLuminance(rgb.r, rgb.g, rgb.b, -0.5)
        };

        if (iconCacheMap.size >= MAX_CACHED_ITEMS) {
            //delete oldest cached values (which are in order of insertions)
            let ctr=0;
            for (let key of iconCacheMap.keys()) {
                if (++ctr > BATCH_SIZE_TO_DELETE)
                    break;
                iconCacheMap.delete(key);
            }
        }

        iconCacheMap.set(this._app.get_id(), backgroundColor);

        return backgroundColor;
    }

    /**
     * Downsample large icons before scanning for the backlight color to
     * improve performance.
     *
     * @param pixBuf
     * @param pixels
     * @param resampleX
     * @param resampleY
     *
     * @return [];
     */
    _resamplePixels (pixels, resampleX, resampleY) {
        let resampledPixels = [];
        // computing the limit outside the for (where it would be repeated at each iteration)
        // for performance reasons
        let limit = pixels.length / (resampleX * resampleY) / 4;
        for (let i = 0; i < limit; i++) {
            let pixel = i * resampleX * resampleY;

            resampledPixels.push(pixels[pixel * 4]);
            resampledPixels.push(pixels[pixel * 4 + 1]);
            resampledPixels.push(pixels[pixel * 4 + 2]);
            resampledPixels.push(pixels[pixel * 4 + 3]);
        }

        return resampledPixels;
    }
};
