// -*- mode: js; js-indent-level: 4; indent-tabs-mode: nil -*-

const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Gtk = imports.gi.Gtk;
const Shell = imports.gi.Shell;
const Signals = imports.signals;

// Use __ () and N__() for the extension gettext domain, and reuse
// the shell domain with the default _() and N_()
const Gettext = imports.gettext.domain('dashtodock');
const __ = Gettext.gettext;
const N__ = function(e) { return e };

const Me = imports.misc.extensionUtils.getCurrentExtension();
const Utils = Me.imports.utils;

const UPDATE_TRASH_DELAY = 500;

/**
 * This class maintains a Shell.App representing the Trash and keeps it
 * up-to-date as the trash fills and is emptied over time.
 */
var Trash = class DashToDock_Trash {

    constructor() {
        this._file = Gio.file_new_for_uri('trash://');
        try {
            this._monitor = this._file.monitor_directory(0, null);
            this._signalId = this._monitor.connect(
                'changed',
                this._onTrashChange.bind(this)
            );
        } catch (e) {
            log(`Impossible to monitor trash: ${e}`)
        }
        this._lastEmpty = true;
        this._empty = true;
        this._schedUpdateId = 0;
        this._updateTrash();
    }

    destroy() {
        if (this._monitor) {
            this._monitor.disconnect(this._signalId);
            this._monitor.run_dispose();
        }
        this._file.run_dispose();
    }

    _onTrashChange() {
        if (this._schedUpdateId) {
            GLib.source_remove(this._schedUpdateId);
        }
        this._schedUpdateId = GLib.timeout_add(
            GLib.PRIORITY_DEFAULT, UPDATE_TRASH_DELAY, () => {
            this._schedUpdateId = 0;
            this._updateTrash();
            return GLib.SOURCE_REMOVE;
        });
    }

    _updateTrash() {
        try {
            let children = this._file.enumerate_children('*', 0, null);
            this._empty = children.next_file(null) == null;
            children.close(null);
        } catch (e) {
            log(`Impossible to enumerate trash children: ${e}`)
            return;
        }

        this._ensureApp();
    }

    _ensureApp() {
        if (this._trashApp == null ||
            this._lastEmpty != this._empty) {
            let trashKeys = new GLib.KeyFile();
            trashKeys.set_string('Desktop Entry', 'Name', __('Trash'));
            trashKeys.set_string('Desktop Entry', 'Icon',
                                 this._empty ? 'user-trash' : 'user-trash-full');
            trashKeys.set_string('Desktop Entry', 'Type', 'Application');
            trashKeys.set_string('Desktop Entry', 'Exec', 'gio open trash:///');
            trashKeys.set_string('Desktop Entry', 'StartupNotify', 'false');
            trashKeys.set_string('Desktop Entry', 'XdtdUri', 'trash:///');
            if (!this._empty) {
                trashKeys.set_string('Desktop Entry', 'Actions', 'empty-trash;');
                trashKeys.set_string('Desktop Action empty-trash', 'Name', __('Empty Trash'));
                trashKeys.set_string('Desktop Action empty-trash', 'Exec',
                                     'dbus-send --print-reply --dest=org.gnome.Nautilus /org/gnome/Nautilus org.gnome.Nautilus.FileOperations.EmptyTrash');
            }

            let trashAppInfo = Gio.DesktopAppInfo.new_from_keyfile(trashKeys);
            this._trashApp = new Shell.App({appInfo: trashAppInfo});
            this._lastEmpty = this._empty;

            this.emit('changed');
        }
    }

    getApp() {
        this._ensureApp();
        return this._trashApp;
    }
}
Signals.addSignalMethods(Trash.prototype);

/**
 * This class maintains Shell.App representations for removable devices
 * plugged into the system, and keeps the list of Apps up-to-date as
 * devices come and go and are mounted and unmounted.
 */
var Removables = class DashToDock_Removables {

    constructor() {
        this._signalsHandler = new Utils.GlobalSignalsHandler();

        this._monitor = Gio.VolumeMonitor.get();
        this._volumeApps = []
        this._mountApps = []

        this._monitor.get_volumes().forEach(
            (volume) => {
                this._onVolumeAdded(this._monitor, volume);
            }
        );

        this._monitor.get_mounts().forEach(
            (mount) => {
                this._onMountAdded(this._monitor, mount);
            }
        );

        this._signalsHandler.add([
            this._monitor,
            'mount-added',
            this._onMountAdded.bind(this)
        ], [
            this._monitor,
            'mount-removed',
            this._onMountRemoved.bind(this)
        ], [
            this._monitor,
            'volume-added',
            this._onVolumeAdded.bind(this)
        ], [
            this._monitor,
            'volume-removed',
            this._onVolumeRemoved.bind(this)
        ]);
    }

    destroy() {
        this._signalsHandler.destroy();
        this._monitor.run_dispose();
    }

    _getWorkingIconName(icon) {
        if (icon instanceof Gio.EmblemedIcon) {
            icon = icon.get_icon();
        }
        if (icon instanceof Gio.ThemedIcon) {
            let iconTheme = Gtk.IconTheme.get_default();
            let names = icon.get_names();
            for (let i = 0; i < names.length; i++) {
                let iconName = names[i];
                if (iconTheme.has_icon(iconName)) {
                    return iconName;
                }
            }
            return '';
        } else {
            return icon.to_string();
        }
    }

    _onVolumeAdded(monitor, volume) {
        if (!volume.can_mount()) {
            return;
        }

        if (volume.get_identifier('class') == 'network') {
            return;
        }

        let activationRoot = volume.get_activation_root();
        if (!activationRoot) {
            // Can't offer to mount a device if we don't know
            // where to mount it.
            // These devices are usually ejectable so you
            // don't normally unmount them anyway.
            return;
        }

        let escapedUri = activationRoot.get_uri()
        let uri = GLib.uri_unescape_string(escapedUri, null);

        let volumeKeys = new GLib.KeyFile();
        volumeKeys.set_string('Desktop Entry', 'Name', volume.get_name());
        volumeKeys.set_string('Desktop Entry', 'Icon', this._getWorkingIconName(volume.get_icon()));
        volumeKeys.set_string('Desktop Entry', 'Type', 'Application');
        volumeKeys.set_string('Desktop Entry', 'Exec', 'gio open "' + uri + '"');
        volumeKeys.set_string('Desktop Entry', 'StartupNotify', 'false');
        volumeKeys.set_string('Desktop Entry', 'XdtdUri', escapedUri);
        volumeKeys.set_string('Desktop Entry', 'Actions', 'mount;');
        volumeKeys.set_string('Desktop Action mount', 'Name', __('Mount'));
        volumeKeys.set_string('Desktop Action mount', 'Exec', 'gio mount "' + uri + '"');
        let volumeAppInfo = Gio.DesktopAppInfo.new_from_keyfile(volumeKeys);
        let volumeApp = new Shell.App({appInfo: volumeAppInfo});
        this._volumeApps.push(volumeApp);
        this.emit('changed');
    }

    _onVolumeRemoved(monitor, volume) {
        for (let i = 0; i < this._volumeApps.length; i++) {
            let app = this._volumeApps[i];
            if (app.get_name() == volume.get_name()) {
                this._volumeApps.splice(i, 1);
            }
        }
        this.emit('changed');
    }

    _onMountAdded(monitor, mount) {
        // Filter out uninteresting mounts
        if (!mount.can_eject() && !mount.can_unmount())
            return;
        if (mount.is_shadowed())
            return;

        let volume = mount.get_volume();
        if (!volume || volume.get_identifier('class') == 'network') {
            return;
        }

        let escapedUri = mount.get_root().get_uri()
        let uri = GLib.uri_unescape_string(escapedUri, null);

        let mountKeys = new GLib.KeyFile();
        mountKeys.set_string('Desktop Entry', 'Name', mount.get_name());
        mountKeys.set_string('Desktop Entry', 'Icon',
                             this._getWorkingIconName(volume.get_icon()));
        mountKeys.set_string('Desktop Entry', 'Type', 'Application');
        mountKeys.set_string('Desktop Entry', 'Exec', 'gio open "' + uri + '"');
        mountKeys.set_string('Desktop Entry', 'StartupNotify', 'false');
        mountKeys.set_string('Desktop Entry', 'XdtdUri', escapedUri);
        mountKeys.set_string('Desktop Entry', 'Actions', 'unmount;');
        if (mount.can_eject()) {
            mountKeys.set_string('Desktop Action unmount', 'Name', __('Eject'));
            mountKeys.set_string('Desktop Action unmount', 'Exec',
                                 'gio mount -e "' + uri + '"');
        } else {
            mountKeys.set_string('Desktop Entry', 'Actions', 'unmount;');
            mountKeys.set_string('Desktop Action unmount', 'Name', __('Unmount'));
            mountKeys.set_string('Desktop Action unmount', 'Exec',
                                 'gio mount -u "' + uri + '"');
        }
        let mountAppInfo = Gio.DesktopAppInfo.new_from_keyfile(mountKeys);
        let mountApp = new Shell.App({appInfo: mountAppInfo});
        this._mountApps.push(mountApp);
        this.emit('changed');
    }

    _onMountRemoved(monitor, mount) {
        for (let i = 0; i < this._mountApps.length; i++) {
            let app = this._mountApps[i];
            if (app.get_name() == mount.get_name()) {
                this._mountApps.splice(i, 1);
            }
        }
        this.emit('changed');
    }

    getApps() {
        // When we have both a volume app and a mount app, we prefer
        // the mount app.
        let apps = new Map();
        this._volumeApps.map(function(app) {
           apps.set(app.get_name(), app);
        });
        this._mountApps.map(function(app) {
           apps.set(app.get_name(), app);
        });

        let ret = [];
        for (let app of apps.values()) {
            ret.push(app);
        }
        return ret;
    }
}
Signals.addSignalMethods(Removables.prototype);
