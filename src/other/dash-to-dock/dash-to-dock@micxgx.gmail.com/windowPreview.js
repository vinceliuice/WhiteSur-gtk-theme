/*
 * Credits:
 * This file is based on code from the Dash to Panel extension by Jason DeRose
 * and code from the Taskbar extension by Zorin OS
 * Some code was also adapted from the upstream Gnome Shell source code.
 */
const Clutter = imports.gi.Clutter;
const GLib = imports.gi.GLib;
const GObject = imports.gi.GObject;
const St = imports.gi.St;
const Main = imports.ui.main;

const Params = imports.misc.params;
const PopupMenu = imports.ui.popupMenu;
const Workspace = imports.ui.workspace;

const Me = imports.misc.extensionUtils.getCurrentExtension();
const Utils = Me.imports.utils;

const PREVIEW_MAX_WIDTH = 250;
const PREVIEW_MAX_HEIGHT = 150;

const PREVIEW_ANIMATION_DURATION = 250;

var WindowPreviewMenu = class DashToDock_WindowPreviewMenu extends PopupMenu.PopupMenu {

    constructor(source) {
        let side = Utils.getPosition();
        super(source, 0.5, side);

        // We want to keep the item hovered while the menu is up
        this.blockSourceEvents = true;

        this._source = source;
        this._app = this._source.app;
        let monitorIndex = this._source.monitorIndex;

        this.actor.add_style_class_name('app-well-menu');
        this.actor.set_style('max-width: '  + (Main.layoutManager.monitors[monitorIndex].width  - 22) + 'px; ' +
                             'max-height: ' + (Main.layoutManager.monitors[monitorIndex].height - 22) + 'px;');
        this.actor.hide();

        // Chain our visibility and lifecycle to that of the source
        this._mappedId = this._source.connect('notify::mapped', () => {
            if (!this._source.mapped)
                this.close();
        });
        this._destroyId = this._source.connect('destroy', this.destroy.bind(this));

        Main.uiGroup.add_actor(this.actor);

        // Change the initialized side where required.
        this._arrowSide = side;
        this._boxPointer._arrowSide = side;
        this._boxPointer._userArrowSide = side;

        this.connect('destroy', this._onDestroy.bind(this));
    }

    _redisplay() {
        if (this._previewBox)
            this._previewBox.destroy();
        this._previewBox = new WindowPreviewList(this._source);
        this.addMenuItem(this._previewBox);
        this._previewBox._redisplay();
    }

    popup() {
        let windows = this._source.getInterestingWindows();
        if (windows.length > 0) {
            this._redisplay();
            this.open();
            this.actor.navigate_focus(null, St.DirectionType.TAB_FORWARD, false);
            this._source.emit('sync-tooltip');
        }
    }

    _onDestroy() {
        if (this._mappedId)
            this._source.disconnect(this._mappedId);

        if (this._destroyId)
            this._source.disconnect(this._destroyId);
    }
};

var WindowPreviewList = class DashToDock_WindowPreviewList extends PopupMenu.PopupMenuSection {

    constructor(source) {
        super();
        this.actor = new St.ScrollView({
            name: 'dashtodockWindowScrollview',
            hscrollbar_policy: St.PolicyType.NEVER,
            vscrollbar_policy: St.PolicyType.NEVER,
            enable_mouse_scrolling: true
        });

        this.actor.connect('scroll-event', this._onScrollEvent.bind(this));

        let position = Utils.getPosition();
        this.isHorizontal = position == St.Side.BOTTOM || position == St.Side.TOP;
        this.box.set_vertical(!this.isHorizontal);
        this.box.set_name('dashtodockWindowList');
        this.actor.add_actor(this.box);
        this.actor._delegate = this;

        this._shownInitially = false;

        this._source = source;
        this.app = source.app;

        this._redisplayId = Main.initializeDeferredWork(this.actor, this._redisplay.bind(this));

        this.actor.connect('destroy', this._onDestroy.bind(this));
        this._stateChangedId = this.app.connect('windows-changed',
                                                this._queueRedisplay.bind(this));
    }

    _queueRedisplay () {
        Main.queueDeferredWork(this._redisplayId);
    }

    _onScrollEvent(actor, event) {
        // Event coordinates are relative to the stage but can be transformed
        // as the actor will only receive events within his bounds.
        let stage_x, stage_y, ok, event_x, event_y, actor_w, actor_h;
        [stage_x, stage_y] = event.get_coords();
        [ok, event_x, event_y] = actor.transform_stage_point(stage_x, stage_y);
        [actor_w, actor_h] = actor.get_size();

        // If the scroll event is within a 1px margin from
        // the relevant edge of the actor, let the event propagate.
        if (event_y >= actor_h - 2)
            return Clutter.EVENT_PROPAGATE;

        // Skip to avoid double events mouse
        if (event.is_pointer_emulated())
            return Clutter.EVENT_STOP;

        let adjustment, delta;

        if (this.isHorizontal)
            adjustment = this.actor.get_hscroll_bar().get_adjustment();
        else
            adjustment = this.actor.get_vscroll_bar().get_adjustment();

        let increment = adjustment.step_increment;

        switch ( event.get_scroll_direction() ) {
        case Clutter.ScrollDirection.UP:
            delta = -increment;
            break;
        case Clutter.ScrollDirection.DOWN:
            delta = +increment;
            break;
        case Clutter.ScrollDirection.SMOOTH:
            let [dx, dy] = event.get_scroll_delta();
            delta = dy*increment;
            delta += dx*increment;
            break;

        }

        adjustment.set_value(adjustment.get_value() + delta);

        return Clutter.EVENT_STOP;
    }

    _onDestroy() {
        this.app.disconnect(this._stateChangedId);
        this._stateChangedId = 0;
    }

    _createPreviewItem(window) {
        let preview = new WindowPreviewMenuItem(window);
        return preview;
    }

    _redisplay () {
        let children = this._getMenuItems().filter(function(actor) {
                return actor._window;
            });

        // Windows currently on the menu
        let oldWin = children.map(function(actor) {
                return actor._window;
            });

        // All app windows with a static order
        let newWin = this._source.getInterestingWindows().sort(function(a, b) {
            return a.get_stable_sequence() > b.get_stable_sequence();
        });

        let addedItems = [];
        let removedActors = [];

        let newIndex = 0;
        let oldIndex = 0;

        while (newIndex < newWin.length || oldIndex < oldWin.length) {
            // No change at oldIndex/newIndex
            if (oldWin[oldIndex] &&
                oldWin[oldIndex] == newWin[newIndex]) {
                oldIndex++;
                newIndex++;
                continue;
            }

            // Window removed at oldIndex
            if (oldWin[oldIndex] &&
                newWin.indexOf(oldWin[oldIndex]) == -1) {
                removedActors.push(children[oldIndex]);
                oldIndex++;
                continue;
            }

            // Window added at newIndex
            if (newWin[newIndex] &&
                oldWin.indexOf(newWin[newIndex]) == -1) {
                addedItems.push({ item: this._createPreviewItem(newWin[newIndex]),
                                  pos: newIndex });
                newIndex++;
                continue;
            }

            // Window moved
            let insertHere = newWin[newIndex + 1] &&
                             newWin[newIndex + 1] == oldWin[oldIndex];
            let alreadyRemoved = removedActors.reduce(function(result, actor) {
                let removedWin = actor._window;
                return result || removedWin == newWin[newIndex];
            }, false);

            if (insertHere || alreadyRemoved) {
                addedItems.push({ item: this._createPreviewItem(newWin[newIndex]),
                                  pos: newIndex + removedActors.length });
                newIndex++;
            } else {
                removedActors.push(children[oldIndex]);
                oldIndex++;
            }
        }

        for (let i = 0; i < addedItems.length; i++)
            this.addMenuItem(addedItems[i].item,
                             addedItems[i].pos);

        for (let i = 0; i < removedActors.length; i++) {
            let item = removedActors[i];
            if (this._shownInitially)
                item._animateOutAndDestroy();
            else
                item.actor.destroy();
        }

        // Skip animations on first run when adding the initial set
        // of items, to avoid all items zooming in at once
        let animate = this._shownInitially;

        if (!this._shownInitially)
            this._shownInitially = true;

        for (let i = 0; i < addedItems.length; i++)
            addedItems[i].item.show(animate);

        // Workaround for https://bugzilla.gnome.org/show_bug.cgi?id=692744
        // Without it, StBoxLayout may use a stale size cache
        this.box.queue_relayout();

        if (newWin.length < 1)
            this._getTopMenu().close(~0);

        // As for upstream:
        // St.ScrollView always requests space horizontally for a possible vertical
        // scrollbar if in AUTOMATIC mode. Doing better would require implementation
        // of width-for-height in St.BoxLayout and St.ScrollView. This looks bad
        // when we *don't* need it, so turn off the scrollbar when that's true.
        // Dynamic changes in whether we need it aren't handled properly.
        let needsScrollbar = this._needsScrollbar();
        let scrollbar_policy = needsScrollbar ?
            St.PolicyType.AUTOMATIC : St.PolicyType.NEVER;
        if (this.isHorizontal)
            this.actor.hscrollbar_policy =  scrollbar_policy;
        else
            this.actor.vscrollbar_policy =  scrollbar_policy;

        if (needsScrollbar)
            this.actor.add_style_pseudo_class('scrolled');
        else
            this.actor.remove_style_pseudo_class('scrolled');
    }

    _needsScrollbar() {
        let topMenu = this._getTopMenu();
        let topThemeNode = topMenu.actor.get_theme_node();
        if (this.isHorizontal) {
            let [topMinWidth, topNaturalWidth] = topMenu.actor.get_preferred_width(-1);
            let topMaxWidth = topThemeNode.get_max_width();
            return topMaxWidth >= 0 && topNaturalWidth >= topMaxWidth;
        } else {
            let [topMinHeight, topNaturalHeight] = topMenu.actor.get_preferred_height(-1);
            let topMaxHeight = topThemeNode.get_max_height();
            return topMaxHeight >= 0 && topNaturalHeight >= topMaxHeight;
        }

    }

    isAnimatingOut() {
        return this.actor.get_children().reduce(function(result, actor) {
                   return result || actor.animatingOut;
               }, false);
    }
};

var WindowPreviewMenuItem = GObject.registerClass(
class DashToDock_WindowPreviewMenuItem extends PopupMenu.PopupBaseMenuItem {
    _init(window, params) {
        super._init(params);

        this._window = window;
        this._destroyId = 0;
        this._windowAddedId = 0;
        [this._width, this._height, this._scale] = this._getWindowPreviewSize(); // This gets the actual windows size for the preview

        // We don't want this: it adds spacing on the left of the item.
        this.remove_child(this._ornamentLabel);
        this.add_style_class_name('dashtodock-app-well-preview-menu-item');

        // Now we don't have to set PREVIEW_MAX_WIDTH and PREVIEW_MAX_HEIGHT as preview size - that made all kinds of windows either stretched or squished (aspect ratio problem)
        this._cloneBin = new St.Bin();
        this._cloneBin.set_size(this._width*this._scale, this._height*this._scale);

        // TODO: improve the way the closebutton is layout. Just use some padding
        // for the moment.
        this._cloneBin.set_style('padding-bottom: 0.5em');

        this.closeButton = new St.Button({ style_class: 'window-close',
                                          x_expand: true,
                                          y_expand: true});
        this.closeButton.add_actor(new St.Icon({ icon_name: 'window-close-symbolic' }));
        this.closeButton.set_x_align(Clutter.ActorAlign.END);
        this.closeButton.set_y_align(Clutter.ActorAlign.START);


        this.closeButton.opacity = 0;
        this.closeButton.connect('clicked', this._closeWindow.bind(this));

        let overlayGroup = new Clutter.Actor({layout_manager: new Clutter.BinLayout(), y_expand: true });

        overlayGroup.add_actor(this._cloneBin);
        overlayGroup.add_actor(this.closeButton);

        let label = new St.Label({ text: window.get_title()});
        label.set_style('max-width: '+PREVIEW_MAX_WIDTH +'px');
        let labelBin = new St.Bin({ child: label,
            x_align: Clutter.ActorAlign.CENTER,
        });

        this._windowTitleId = this._window.connect('notify::title', () => {
                                  label.set_text(this._window.get_title());
                              });

        let box = new St.BoxLayout({ vertical: true,
                                     reactive:true,
                                     x_expand:true });
        box.add(overlayGroup);
        box.add(labelBin);
        this.add_actor(box);

        this._cloneTexture(window);

        this.connect('destroy', this._onDestroy.bind(this));
    }

    _getWindowPreviewSize() {
        let mutterWindow = this._window.get_compositor_private();
        let [width, height] = mutterWindow.get_size();
        let scale = Math.min(1.0, PREVIEW_MAX_WIDTH/width, PREVIEW_MAX_HEIGHT/height);
        return [width, height, scale];
    }

    _cloneTexture(metaWin){

        let mutterWindow = metaWin.get_compositor_private();

        // Newly-created windows are added to a workspace before
        // the compositor finds out about them...
        // Moreover sometimes they return an empty texture, thus as a workarounf also check for it size
        if (!mutterWindow || !mutterWindow.get_texture() || !mutterWindow.get_size()[0]) {
            this._cloneTextureId = GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
                // Check if there's still a point in getting the texture,
                // otherwise this could go on indefinitely
                if (metaWin.get_workspace())
                    this._cloneTexture(metaWin);
                this._cloneTextureId = 0;
                return GLib.SOURCE_REMOVE;
            });
            GLib.Source.set_name_by_id(this._cloneTextureId, '[dash-to-dock] this._cloneTexture');
            return;
        }

        let clone = new Clutter.Clone ({ source: mutterWindow,
                                         reactive: true,
                                         width: this._width * this._scale,
                                         height: this._height * this._scale });

        // when the source actor is destroyed, i.e. the window closed, first destroy the clone
        // and then destroy the menu item (do this animating out)
        this._destroyId = mutterWindow.connect('destroy', () => {
            clone.destroy();
            this._destroyId = 0; // avoid to try to disconnect this signal from mutterWindow in _onDestroy(),
                                 // as the object was just destroyed
            this._animateOutAndDestroy();
        });

        this._clone = clone;
        this._mutterWindow = mutterWindow;
        this._cloneBin.set_child(this._clone);

        this._clone.connect('destroy', () => {
            if (this._destroyId) {
                mutterWindow.disconnect(this._destroyId);
                this._destroyId = 0;
            }
            this._clone = null;
        })
    }

    _windowCanClose() {
        return this._window.can_close() &&
               !this._hasAttachedDialogs();
    }

    _closeWindow(actor) {
        this._workspace = this._window.get_workspace();

        // This mechanism is copied from the workspace.js upstream code
        // It forces window activation if the windows don't get closed,
        // for instance because asking user confirmation, by monitoring the opening of
        // such additional confirmation window
        this._windowAddedId = this._workspace.connect('window-added',
                                                      this._onWindowAdded.bind(this));

        this.deleteAllWindows();
    }

    deleteAllWindows() {
        // Delete all windows, starting from the bottom-most (most-modal) one
        //let windows = this._window.get_compositor_private().get_children();
        let windows = this._clone.get_children();
        for (let i = windows.length - 1; i >= 1; i--) {
            let realWindow = windows[i].source;
            let metaWindow = realWindow.meta_window;

            metaWindow.delete(global.get_current_time());
        }

        this._window.delete(global.get_current_time());
    }

    _onWindowAdded(workspace, win) {
        let metaWindow = this._window;

        if (win.get_transient_for() == metaWindow) {
            workspace.disconnect(this._windowAddedId);
            this._windowAddedId = 0;

            // use an idle handler to avoid mapping problems -
            // see comment in Workspace._windowAdded
            let activationEvent = Clutter.get_current_event();
            let id = GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
                this.emit('activate', activationEvent);
                return GLib.SOURCE_REMOVE;
            });
            GLib.Source.set_name_by_id(id, '[dash-to-dock] this.emit');
        }
    }

    _hasAttachedDialogs() {
        // count trasient windows
        let n=0;
        this._window.foreach_transient(function(){n++;});
        return n>0;
    }

    vfunc_key_focus_in() {
        super.vfunc_key_focus_in();
        this._showCloseButton();
    }

    vfunc_key_focus_out() {
        super.vfunc_key_focus_out();
        this._hideCloseButton();
    }

    vfunc_enter_event(crossingEvent) {
        this._showCloseButton();
        return super.vfunc_enter_event(crossingEvent);
    }

    vfunc_leave_event(crossingEvent) {
        this._hideCloseButton();
        return super.vfunc_leave_event(crossingEvent);
    }

    _idleToggleCloseButton() {
        this._idleToggleCloseId = 0;

        this._hideCloseButton();

        return GLib.SOURCE_REMOVE;
    }

    _showCloseButton() {

        if (this._windowCanClose()) {
            this.closeButton.show();
            this.closeButton.remove_all_transitions();
            this.closeButton.ease({
                opacity: 255,
                duration: Workspace.WINDOW_OVERLAY_FADE_TIME,
                mode: Clutter.AnimationMode.EASE_OUT_QUAD
            });
        }
    }

    _hideCloseButton() {
        if (this.closeButton.has_pointer ||
            this.get_children().some(a => a.has_pointer))
            return;

        this.closeButton.remove_all_transitions();
        this.closeButton.ease({
            opacity: 0,
            duration: Workspace.WINDOW_OVERLAY_FADE_TIME,
            mode: Clutter.AnimationMode.EASE_IN_QUAD
        });
    }

    show(animate) {
        let fullWidth = this.get_width();

        this.opacity = 0;
        this.set_width(0);

        let time = animate ? PREVIEW_ANIMATION_DURATION : 0;
        this.remove_all_transitions();
        this.ease({
            opacity: 255,
            width: fullWidth,
            duration: time,
            mode: Clutter.AnimationMode.EASE_IN_OUT_QUAD,
        });
    }

    _animateOutAndDestroy() {
        this.remove_all_transitions();
        this.ease({
            opacity: 0,
            duration: PREVIEW_ANIMATION_DURATION,
        });

        this.ease({
            width: 0,
            height: 0,
            duration: PREVIEW_ANIMATION_DURATION,
            delay: PREVIEW_ANIMATION_DURATION,
            onComplete: () => this.destroy()
        });
    }

    activate() {
        this._getTopMenu().close();
        Main.activateWindow(this._window);
    }

    _onDestroy() {
        if (this._cloneTextureId) {
            GLib.source_remove(this._cloneTextureId);
            this._cloneTextureId = 0;
        }

        if (this._windowAddedId > 0) {
            this._workspace.disconnect(this._windowAddedId);
            this._windowAddedId = 0;
        }

        if (this._destroyId > 0) {
            this._mutterWindow.disconnect(this._destroyId);
            this._destroyId = 0;
        }

        if (this._windowTitleId > 0) {
            this._window.disconnect(this._windowTitleId);
            this._windowTitleId = 0;
        }
    }
});