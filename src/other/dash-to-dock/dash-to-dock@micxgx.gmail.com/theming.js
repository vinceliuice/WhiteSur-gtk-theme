// -*- mode: js; js-indent-level: 4; indent-tabs-mode: nil -*-

const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Signals = imports.signals;
const Meta = imports.gi.Meta;
const Shell = imports.gi.Shell;
const St = imports.gi.St;
const Clutter = imports.gi.Clutter;

const AppDisplay = imports.ui.appDisplay;
const AppFavorites = imports.ui.appFavorites;
const Dash = imports.ui.dash;
const DND = imports.ui.dnd;
const IconGrid = imports.ui.iconGrid;
const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const Workspace = imports.ui.workspace;

const Me = imports.misc.extensionUtils.getCurrentExtension();
const Docking = Me.imports.docking;
const Utils = Me.imports.utils;

/*
 * DEFAULT:  transparency given by theme
 * FIXED:    constant transparency chosen by user
 * DYNAMIC:  apply 'transparent' style when no windows are close to the dock
 * */
const TransparencyMode = {
    DEFAULT:  0,
    FIXED:    1,
    DYNAMIC:  3
};

/**
 * Manage theme customization and custom theme support
 */
var ThemeManager = class DashToDock_ThemeManager {

    constructor(dock) {
        this._signalsHandler = new Utils.GlobalSignalsHandler();
        this._bindSettingsChanges();
        this._actor = dock;
        this._dash = dock.dash;

        // initialize colors with generic values
        this._customizedBackground = {red: 0, green: 0, blue: 0, alpha: 0};
        this._customizedBorder = {red: 0, green: 0, blue: 0, alpha: 0};
        this._transparency = new Transparency(dock);

        this._signalsHandler.add([
            // When theme changes re-obtain default background color
            St.ThemeContext.get_for_stage (global.stage),
            'changed',
            this.updateCustomTheme.bind(this)
        ], [
            // update :overview pseudoclass
            Main.overview,
            'showing',
            this._onOverviewShowing.bind(this)
        ], [
            Main.overview,
            'hiding',
            this._onOverviewHiding.bind(this)
        ]);

        this._updateCustomStyleClasses();

        // destroy themeManager when the managed actor is destroyed (e.g. extension unload)
        // in order to disconnect signals
        this._actor.connect('destroy', this.destroy.bind(this));

    }

    destroy() {
        this._signalsHandler.destroy();
        this._transparency.destroy();
    }

    _onOverviewShowing() {
        this._actor.add_style_pseudo_class('overview');
    }

    _onOverviewHiding() {
        this._actor.remove_style_pseudo_class('overview');
    }

    _updateDashOpacity() {
        let newAlpha = Docking.DockManager.settings.get_double('background-opacity');

        let [backgroundColor, borderColor] = this._getDefaultColors();

        if (backgroundColor==null)
            return;

        // Get the background and border alphas. We check the background alpha
        // for a minimum of .001 to prevent division by 0 errors
        let backgroundAlpha = Math.max(Math.round(backgroundColor.alpha/2.55)/100, .001);
        let borderAlpha = Math.round(borderColor.alpha/2.55)/100;

        // The border and background alphas should remain in sync
        // We also limit the borderAlpha to a maximum of 1 (full opacity)
        borderAlpha = Math.min((borderAlpha/backgroundAlpha)*newAlpha, 1);

        this._customizedBackground = 'rgba(' +
            backgroundColor.red + ',' +
            backgroundColor.green + ',' +
            backgroundColor.blue + ',' +
            newAlpha + ')';

        this._customizedBorder = 'rgba(' +
            borderColor.red + ',' +
            borderColor.green + ',' +
            borderColor.blue + ',' +
            borderAlpha + ')';

    }

    _getDefaultColors() {
        // Prevent shell crash if the actor is not on the stage.
        // It happens enabling/disabling repeatedly the extension
        if (!this._dash._container.get_stage())
            return [null, null];

        // Remove custom style
        let oldStyle = this._dash._container.get_style();
        this._dash._container.set_style(null);

        let themeNode = this._dash._container.get_theme_node();
        this._dash._container.set_style(oldStyle);

        let backgroundColor = themeNode.get_background_color();

        // Just in case the theme has different border colors ..
        // We want to find the inside border-color of the dock because it is
        // the side most visible to the user. We do this by finding the side
        // opposite the position
        let position = Utils.getPosition();
        let side = position + 2;
        if (side > 3)
            side = Math.abs(side - 4);

        let borderColor = themeNode.get_border_color(side);

        return [backgroundColor, borderColor];
    }

    _updateDashColor() {
        // Retrieve the color. If needed we will adjust it before passing it to
        // this._transparency.
        let [backgroundColor, borderColor] = this._getDefaultColors();

        if (backgroundColor==null)
            return;

        let settings = Docking.DockManager.settings;

        if (settings.get_boolean('custom-background-color')) {
            // When applying a custom color, we need to check the alpha value,
            // if not the opacity will always be overridden by the color below.
            // Note that if using 'dynamic' transparency modes,
            // the opacity will be set by the opaque/transparent styles anyway.
            let newAlpha = Math.round(backgroundColor.alpha/2.55)/100;
            if (settings.get_enum('transparency-mode') == TransparencyMode.FIXED)
                newAlpha = settings.get_double('background-opacity');

            backgroundColor = settings.get_string('background-color');
          
            this._customizedBackground = backgroundColor;

            this._customizedBorder = this._customizedBackground;

            // backgroundColor is a string like rgb(0,0,0)
            const color = Clutter.Color.from_string(backgroundColor);
            color.alpha = newAlpha;

            this._transparency.setColor(color);
        } else { 
            // backgroundColor is a Clutter.Color object
            this._transparency.setColor(backgroundColor);
        }
    }

    _updateCustomStyleClasses() {
        let settings = Docking.DockManager.settings;

        if (settings.get_boolean('apply-custom-theme'))
            this._actor.add_style_class_name('dashtodock');
        else
            this._actor.remove_style_class_name('dashtodock');

        if (settings.get_boolean('custom-theme-shrink'))
            this._actor.add_style_class_name('shrink');
        else
            this._actor.remove_style_class_name('shrink');

        if (settings.get_enum('running-indicator-style') !== 0)
            this._actor.add_style_class_name('running-dots');
        else
            this._actor.remove_style_class_name('running-dots');

        // If not the built-in theme option is not selected
        if (!settings.get_boolean('apply-custom-theme')) {
            if (settings.get_boolean('force-straight-corner'))
                this._actor.add_style_class_name('straight-corner');
            else
                this._actor.remove_style_class_name('straight-corner');
        } else {
            this._actor.remove_style_class_name('straight-corner');
        }
    }

    updateCustomTheme() {
        this._updateCustomStyleClasses();
        this._updateDashOpacity();
        this._updateDashColor();
        this._adjustTheme();
        this._dash._redisplay();
    }

    /**
     * Reimported back and adapted from atomdock
     */
    _adjustTheme() {
        // Prevent shell crash if the actor is not on the stage.
        // It happens enabling/disabling repeatedly the extension
        if (!this._dash._background.get_stage())
            return;

        let settings = Docking.DockManager.settings;

        // Remove prior style edits
        this._dash._background.set_style(null);
        this._transparency.disable();

        // If built-in theme is enabled do nothing else
        if (settings.get_boolean('apply-custom-theme'))
            return;

        let newStyle = '';
        let position = Utils.getPosition(settings);

        // obtain theme border settings
        let themeNode = this._dash._background.get_theme_node();
        let borderColor = themeNode.get_border_color(St.Side.TOP);
        let borderWidth = themeNode.get_border_width(St.Side.TOP);

        // We're copying border and corner styles to left border and top-left
        // corner, also removing bottom border and bottom-right corner styles
        let borderInner = '';
        let borderMissingStyle = '';

        if (this._rtl && (position != St.Side.RIGHT))
            borderMissingStyle = 'border-right: ' + borderWidth + 'px solid ' +
                   borderColor.to_string() + ';';
        else if (!this._rtl && (position != St.Side.LEFT))
            borderMissingStyle = 'border-left: ' + borderWidth + 'px solid ' +
                   borderColor.to_string() + ';';

        newStyle = borderMissingStyle;

        // I do call set_style possibly twice so that only the background gets the transition.
        // The transition-property css rules seems to be unsupported
        this._dash._background.set_style(newStyle);

        // Customize background
        let fixedTransparency = settings.get_enum('transparency-mode') == TransparencyMode.FIXED;
        let defaultTransparency = settings.get_enum('transparency-mode') == TransparencyMode.DEFAULT;
        if (!defaultTransparency && !fixedTransparency) {
            this._transparency.enable();
        }
        else if (!defaultTransparency || settings.get_boolean('custom-background-color')) {
            newStyle = newStyle + 'background-color:'+ this._customizedBackground + '; ' +
                       'border-color:'+ this._customizedBorder + '; ' +
                       'transition-delay: 0s; transition-duration: 0.250s;';
            this._dash._background.set_style(newStyle);
        }
    }

    _bindSettingsChanges() {
        let keys = ['transparency-mode',
                    'customize-alphas',
                    'min-alpha',
                    'max-alpha',
                    'background-opacity',
                    'custom-background-color',
                    'background-color',
                    'apply-custom-theme',
                    'custom-theme-shrink',
                    'custom-theme-running-dots',
                    'extend-height',
                    'force-straight-corner'];

        keys.forEach(function(key) {
            this._signalsHandler.add([
                Docking.DockManager.settings,
                'changed::' + key,
                this.updateCustomTheme.bind(this)
           ]);
        }, this);
    }
};

/**
 * The following class is based on the following upstream commit:
 * https://git.gnome.org/browse/gnome-shell/commit/?id=447bf55e45b00426ed908b1b1035f472c2466956
 * Transparency when free-floating
 */
var Transparency = class DashToDock_Transparency {

    constructor(dock) {
        this._dash = dock.dash;
        this._actor = this._dash._container;
        this._backgroundActor = this._dash._background;
        this._dockActor = dock;
        this._dock = dock;
        this._panel = Main.panel;
        this._position = Utils.getPosition();

        // All these properties are replaced with the ones in the .dummy-opaque and .dummy-transparent css classes
        this._backgroundColor = '0,0,0';
        this._transparentAlpha = '0.2';
        this._opaqueAlpha = '1';
        this._transparentAlphaBorder = '0.1';
        this._opaqueAlphaBorder = '0.5';
        this._transparentTransition = '0ms';
        this._opaqueTransition = '0ms';
        this._base_actor_style = "";

        this._signalsHandler = new Utils.GlobalSignalsHandler();
        this._injectionsHandler = new Utils.InjectionsHandler();
        this._trackedWindows = new Map();
    }

    enable() {
        // ensure I never double-register/inject
        // although it should never happen
        this.disable();

        this._base_actor_style = this._actor.get_style();
        if (this._base_actor_style == null) {
            this._base_actor_style = "";
        }

        this._signalsHandler.addWithLabel('transparency', [
            global.window_group,
            'actor-added',
            this._onWindowActorAdded.bind(this)
        ], [
            global.window_group,
            'actor-removed',
            this._onWindowActorRemoved.bind(this)
        ], [
            global.window_manager,
            'switch-workspace',
            this._updateSolidStyle.bind(this)
        ], [
            Main.overview,
            'hiding',
            this._updateSolidStyle.bind(this)
        ], [
            Main.overview,
            'showing',
            this._updateSolidStyle.bind(this)
        ]);

        // Window signals
        global.window_group.get_children().filter(function(child) {
            // An irrelevant window actor ('Gnome-shell') produces an error when the signals are
            // disconnected, therefore do not add signals to it.
            return child instanceof Meta.WindowActor &&
                   child.get_meta_window().get_wm_class() !== 'Gnome-shell';
        }).forEach(function(win) {
            this._onWindowActorAdded(null, win);
        }, this);

        if (this._actor.get_stage())
            this._updateSolidStyle();

        this._updateStyles();
        this._updateSolidStyle();

        this.emit('transparency-enabled');
    }

    disable() {
        // ensure I never double-register/inject
        // although it should never happen
        this._signalsHandler.removeWithLabel('transparency');

        for (let key of this._trackedWindows.keys())
            this._trackedWindows.get(key).forEach(id => {
                key.disconnect(id);
            });
        this._trackedWindows.clear();

        this.emit('transparency-disabled');
    }

    destroy() {
        this.disable();
        this._signalsHandler.destroy();
        this._injectionsHandler.destroy();
    }

    _onWindowActorAdded(container, metaWindowActor) {
        let signalIds = [];
        ['notify::allocation', 'notify::visible'].forEach(s => {
            signalIds.push(metaWindowActor.connect(s, this._updateSolidStyle.bind(this)));
        });
        this._trackedWindows.set(metaWindowActor, signalIds);
    }

    _onWindowActorRemoved(container, metaWindowActor) {
        if (!this._trackedWindows.get(metaWindowActor))
            return;

        this._trackedWindows.get(metaWindowActor).forEach(id => {
            metaWindowActor.disconnect(id);
        });
        this._trackedWindows.delete(metaWindowActor);
        this._updateSolidStyle();
    }

    _updateSolidStyle() {
        let isNear = this._dockIsNear();
        if (isNear) {
            this._backgroundActor.set_style(this._opaque_style);
            this._dockActor.remove_style_class_name('transparent');
            this._dockActor.add_style_class_name('opaque');
        }
        else {
            this._backgroundActor.set_style(this._transparent_style);
            this._dockActor.remove_style_class_name('opaque');
            this._dockActor.add_style_class_name('transparent');
        }

        this.emit('solid-style-updated', isNear);
    }

    _dockIsNear() {
        if (this._dockActor.has_style_pseudo_class('overview'))
            return false;
        /* Get all the windows in the active workspace that are in the primary monitor and visible */
        let activeWorkspace = global.workspace_manager.get_active_workspace();
        let dash = this._dash;
        let windows = activeWorkspace.list_windows().filter(function(metaWindow) {
            return metaWindow.get_monitor() === dash._monitorIndex &&
                   metaWindow.showing_on_its_workspace() &&
                   metaWindow.get_window_type() != Meta.WindowType.DESKTOP;
        });

        /* Check if at least one window is near enough to the panel.
         * If the dock is hidden, we need to account for the space it would take
         * up when it slides out. This is avoid an ugly transition.
         * */
        let factor = 0;
        if (!Docking.DockManager.settings.get_boolean('dock-fixed') &&
            this._dock.getDockState() == Docking.State.HIDDEN)
            factor = 1;
        let [leftCoord, topCoord] = this._actor.get_transformed_position();
        let threshold;
        if (this._position === St.Side.LEFT)
            threshold = leftCoord + this._actor.get_width() * (factor + 1);
        else if (this._position === St.Side.RIGHT)
            threshold = leftCoord - this._actor.get_width() * factor;
        else if (this._position === St.Side.TOP)
            threshold = topCoord + this._actor.get_height() * (factor + 1);
        else
            threshold = topCoord - this._actor.get_height() * factor;

        let scale = St.ThemeContext.get_for_stage(global.stage).scale_factor;
        let isNearEnough = windows.some((metaWindow) => {
            let coord;
            if (this._position === St.Side.LEFT) {
                coord = metaWindow.get_frame_rect().x;
                return coord < threshold + 5 * scale;
            }
            else if (this._position === St.Side.RIGHT) {
                coord = metaWindow.get_frame_rect().x + metaWindow.get_frame_rect().width;
                return coord > threshold - 5 * scale;
            }
            else if (this._position === St.Side.TOP) {
                coord = metaWindow.get_frame_rect().y;
                return coord < threshold + 5 * scale;
            }
            else {
                coord = metaWindow.get_frame_rect().y + metaWindow.get_frame_rect().height;
                return coord > threshold - 5 * scale;
            }
        });

        return isNearEnough;
    }

    _updateStyles() {
        this._getAlphas();

        this._transparent_style = this._base_actor_style +
            'background-color: rgba(' +
            this._backgroundColor + ', ' + this._transparentAlpha + ');' +
            'border-color: rgba(' +
            this._backgroundColor + ', ' + this._transparentAlphaBorder + ');' +
            'transition-duration: ' + this._transparentTransition + 'ms;';

        this._opaque_style = this._base_actor_style +
            'background-color: rgba(' +
            this._backgroundColor + ', ' + this._opaqueAlpha + ');' +
            'border-color: rgba(' +
            this._backgroundColor + ',' + this._opaqueAlphaBorder + ');' +
            'transition-duration: ' + this._opaqueTransition + 'ms;';

        this.emit('styles-updated');
    }

    setColor(color) {
        this._backgroundColor = color.red + ',' + color.green + ',' + color.blue;
        this._updateStyles();
    }

    _getAlphas() {
        // Create dummy object and add to the uiGroup to get it to the stage
        let dummyObject = new St.Bin({
            name: 'dashtodockContainer',
        });
        Main.uiGroup.add_child(dummyObject);

        dummyObject.add_style_class_name('dummy-opaque');
        let themeNode = dummyObject.get_theme_node();
        this._opaqueAlpha = themeNode.get_background_color().alpha / 255;
        this._opaqueAlphaBorder = themeNode.get_border_color(0).alpha / 255;
        this._opaqueTransition = themeNode.get_transition_duration();

        dummyObject.add_style_class_name('dummy-transparent');
        themeNode = dummyObject.get_theme_node();
        this._transparentAlpha = themeNode.get_background_color().alpha / 255;
        this._transparentAlphaBorder = themeNode.get_border_color(0).alpha / 255;
        this._transparentTransition = themeNode.get_transition_duration();

        Main.uiGroup.remove_child(dummyObject);

        let settings = Docking.DockManager.settings;

        if (settings.get_boolean('customize-alphas')) {
            this._opaqueAlpha = settings.get_double('max-alpha');
            this._opaqueAlphaBorder = this._opaqueAlpha / 2;
            this._transparentAlpha = settings.get_double('min-alpha');
            this._transparentAlphaBorder = this._transparentAlpha / 2;
        }
    }
};
Signals.addSignalMethods(Transparency.prototype);
