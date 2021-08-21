// -*- mode: js; js-indent-level: 4; indent-tabs-mode: nil -*-

const Gio = imports.gi.Gio;

const Me = imports.misc.extensionUtils.getCurrentExtension();
const DbusmenuUtils = Me.imports.dbusmenuUtils;

const Dbusmenu = DbusmenuUtils.haveDBusMenu();

var LauncherEntryRemoteModel = class DashToDock_LauncherEntryRemoteModel {

    constructor() {
        this._entrySourceStacks = new Map();
        this._remoteMaps = new Map();

        this._launcher_entry_dbus_signal_id =
            Gio.DBus.session.signal_subscribe(null, // sender
                'com.canonical.Unity.LauncherEntry', // iface
                'Update', // member
                null, // path
                null, // arg0
                Gio.DBusSignalFlags.NONE,
                (connection, sender_name, object_path, interface_name, signal_name, parameters) =>
                    this._onUpdate(sender_name, ...parameters.deep_unpack()));

        this._dbus_name_owner_changed_signal_id =
            Gio.DBus.session.signal_subscribe('org.freedesktop.DBus',  // sender
                'org.freedesktop.DBus',  // interface
                'NameOwnerChanged',      // member
                '/org/freedesktop/DBus', // path
                null,                    // arg0
                Gio.DBusSignalFlags.NONE,
                (connection, sender_name, object_path, interface_name, signal_name, parameters) =>
                    this._onDBusNameChange(...parameters.deep_unpack().slice(1)));

        this._acquireUnityDBus();
    }

    destroy() {
        if (this._launcher_entry_dbus_signal_id) {
            Gio.DBus.session.signal_unsubscribe(this._launcher_entry_dbus_signal_id);
        }

        if (this._dbus_name_owner_changed_signal_id) {
            Gio.DBus.session.signal_unsubscribe(this._dbus_name_owner_changed_signal_id);
        }

        this._releaseUnityDBus();
    }

    _lookupStackById(appId) {
        let sourceStack = this._entrySourceStacks.get(appId);
        if (!sourceStack) {
            this._entrySourceStacks.set(appId, sourceStack = new PropertySourceStack(new LauncherEntry(), launcherEntryDefaults));
        }
        return sourceStack;
    }

    lookupById(appId) {
        return this._lookupStackById(appId).target;
    }

    _acquireUnityDBus() {
        if (!this._unity_bus_id) {
            this._unity_bus_id = Gio.DBus.session.own_name('com.canonical.Unity',
                Gio.BusNameOwnerFlags.ALLOW_REPLACEMENT | Gio.BusNameOwnerFlags.REPLACE,
                null, () => this._unity_bus_id = 0);
        }
    }

    _releaseUnityDBus() {
        if (this._unity_bus_id) {
            Gio.DBus.session.unown_name(this._unity_bus_id);
            this._unity_bus_id = 0;
        }
    }

    _onDBusNameChange(before, after) {
        if (!before || !this._remoteMaps.size) {
            return;
        }
        const remoteMap = this._remoteMaps.get(before);
        if (!remoteMap) {
            return;
        }
        this._remoteMaps.delete(before);
        if (after && !this._remoteMaps.has(after)) {
            this._remoteMaps.set(after, remoteMap);
        } else {
            for (const [appId, remote] of remoteMap) {
                const sourceStack = this._entrySourceStacks.get(appId);
                const changed = sourceStack.remove(remote);
                if (changed) {
                    sourceStack.target._emitChangedEvents(changed);
                }
            }
        }
    }

    _onUpdate(senderName, appUri, properties) {
        if (!senderName) {
            return;
        }

        const appId = appUri.replace(/(^\w+:|^)\/\//, '');
        if (!appId) {
            return;
        }

        let remoteMap = this._remoteMaps.get(senderName);
        if (!remoteMap) {
            this._remoteMaps.set(senderName, remoteMap = new Map());
        }
        let remote = remoteMap.get(appId);
        if (!remote) {
            remoteMap.set(appId, remote = Object.assign({}, launcherEntryDefaults));
        }
        for (const name in properties) {
            if (name === 'quicklist' && Dbusmenu) {
                const quicklistPath = properties[name].unpack();
                if (quicklistPath && (!remote._quicklistMenuClient || remote._quicklistMenuClient.dbus_object !== quicklistPath)) {
                    remote.quicklist = null;
                    let menuClient = remote._quicklistMenuClient;
                    if (menuClient) {
                        menuClient.dbus_object = quicklistPath;
                    } else {
                        // This property should not be enumerable
                        Object.defineProperty(remote, '_quicklistMenuClient', {
                            writable: true,
                            value: menuClient = new Dbusmenu.Client({ dbus_name: senderName, dbus_object: quicklistPath }),
                        });
                    }
                    const handler = () => {
                        const root = menuClient.get_root();
                        if (remote.quicklist !== root) {
                            remote.quicklist = root;
                            if (sourceStack.isTop(remote)) {
                                sourceStack.target.quicklist = root;
                                sourceStack.target._emitChangedEvents(['quicklist']);
                            }
                        }
                    };
                    menuClient.connect(Dbusmenu.CLIENT_SIGNAL_ROOT_CHANGED, handler);
                }
            } else {
                remote[name] = properties[name].unpack();
            }
        }

        const sourceStack = this._lookupStackById(appId);
        sourceStack.target._emitChangedEvents(sourceStack.update(remote));
    }
};

const launcherEntryDefaults = {
    count: 0,
    progress: 0,
    urgent: false,
    quicklist: null,
    'count-visible': false,
    'progress-visible': false,
};

const LauncherEntry = class DashToDock_LauncherEntry {
    constructor() {
        this._connections = new Map();
        this._handlers = new Map();
        this._nextId = 0;
    }

    connect(eventNames, callback) {
        if (typeof eventNames === 'string') {
            eventNames = [eventNames];
        }
        callback(this, this);
        const id = this._nextId++;
        const handler = { id, callback };
        eventNames.forEach(name => {
            let handlerList = this._handlers.get(name);
            if (!handlerList) {
                this._handlers.set(name, handlerList = []);
            }
            handlerList.push(handler);
        });
        this._connections.set(id, eventNames);
        return id;
    }

    disconnect(id) {
        const eventNames = this._connections.get(id);
        if (!eventNames) {
            return;
        }
        this._connections.delete(id);
        eventNames.forEach(name => {
            const handlerList = this._handlers.get(name);
            if (handlerList) {
                for (let i = 0, iMax = handlerList.length; i < iMax; i++) {
                    if (handlerList[i].id === id) {
                        handlerList.splice(i, 1);
                        break;
                    }
                }
            }
        });
    }

    _emitChangedEvents(propertyNames) {
        const handlers = new Set();
        propertyNames.forEach(name => {
            const handlerList = this._handlers.get(name + '-changed');
            if (handlerList) {
                for (let i = 0, iMax = handlerList.length; i < iMax; i++) {
                    handlers.add(handlerList[i]);
                }
            }
        });
        Array.from(handlers).sort((x, y) => x.id - y.id).forEach(handler => handler.callback(this, this));
    }
}

for (const name in launcherEntryDefaults) {
    const jsName = name.replace(/-/g, '_');
    LauncherEntry.prototype[jsName] = launcherEntryDefaults[name];
    if (jsName !== name) {
        Object.defineProperty(LauncherEntry.prototype, name, {
            get() {
                return this[jsName];
            },
            set(value) {
                this[jsName] = value;
            },
        });
    }
}

const PropertySourceStack = class DashToDock_PropertySourceStack {
    constructor(target, bottom) {
        this.target = target;
        this._bottom = bottom;
        this._stack = [];
    }

    isTop(source) {
        return this._stack.length > 0 && this._stack[this._stack.length - 1] === source;
    }

    update(source) {
        if (!this.isTop(source)) {
            this.remove(source);
            this._stack.push(source);
        }
        return this._assignFrom(source);
    }

    remove(source) {
        const stack = this._stack;
        const top = stack[stack.length - 1];
        if (top === source) {
            stack.length--;
            return this._assignFrom(stack.length > 0 ? stack[stack.length - 1] : this._bottom);
        }
        for (let i = 0, iMax = stack.length; i < iMax; i++) {
            if (stack[i] === source) {
                stack.splice(i, 1);
                break;
            }
        }
    }

    _assignFrom(source) {
        const changedProperties = [];
        for (const name in source) {
            if (this.target[name] !== source[name]) {
                this.target[name] = source[name];
                changedProperties.push(name);
            }
        }
        return changedProperties;
    }
}
