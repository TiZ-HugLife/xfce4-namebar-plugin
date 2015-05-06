// Copyright (c) 2010- Trent McPheron <twilightinzero@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

using Xfce;
using Gtk;
using Pango;
using Wnck;


///////////////////
// Init stuff
///////////////////

[ModuleInit]
public Type xfce_panel_module_init (TypeModule module) {
    return typeof (NamebarPlugin);
}


///////////////////
// Namebar
///////////////////

public class NamebarPlugin : PanelPlugin {

    ///////////////////
    // Properties
    ///////////////////

    public bool   only_max        { get; set; default = true; }
    public bool   hide_max        { get; set; default = false; }
    public bool   hide_min        { get; set; default = false; }
    public bool   hide_close      { get; set; default = false; }
    public bool   hide_icon       { get; set; default = false; }
    public bool   hide_title      { get; set; default = false; }
    public int    size            { get; set; default = 240; }
    public bool   expand          { get; set; default = true; }
    public uint8  align           { get; set; default = 1; }
    public bool   active_bold     { get; set; default = true; }
    public bool   passive_bold    { get; set; default = true; }
    public bool   custom_colors   { get; set; default = true; }
    public Color  active_color    { get; set; }
    public Color  passive_color   { get; set; }
    public Theme  theme           { get; set; }

    public Color active_default { get {
        Color col = Color();
        Gtk.Style style = get_style();
        col.red = style.fg[StateType.NORMAL].red;
        col.green = style.fg[StateType.NORMAL].green;
        col.blue = style.fg[StateType.NORMAL].blue;
        return col;
    } }
    
    public Color passive_default { get {
        Color col = Color();
        Gtk.Style style = get_style();
        col.red = style.fg[StateType.INSENSITIVE].red;
        col.green = style.fg[StateType.INSENSITIVE].green;
        col.blue = style.fg[StateType.INSENSITIVE].blue;
        return col;
    } }
    
    public float align_float { get {
        return align == 0 ? 0.0f : (align == 2 ? 1.0f : 0.5f);
    } }

    ///////////////////
    // Fields
    ///////////////////

    // Wnck stuff. You may be wondering, as I did when I
    // first started this port: "Why track two windows?"
    // The reason why is to catch when an unmaximized
    // active window becomes maximized. When tracking
    // only one window, this isn't possible.
    private unowned Screen screen;
    private unowned Wnck.Window shown_window;
    private unowned Wnck.Window active_window;

    // Gtk widgets.
    private HBox box;
    private Image window_icon;
    private Image minimize_icon;
    private Image max_res_icon;
    private Image close_icon;
    private Label title_label;


    ///////////////////
    // Constructor
    ///////////////////

    // Fake constructor, gets rid of warning.
    public NamebarPlugin () {
        GLib.Object();
    }

    // Real constructor!
    public override void @construct () {
        // Default colors.
        active_color = active_default;
        passive_color = passive_default;

        // Load settings from the rc file.
        KeyFile keyfile = new KeyFile();
        try {
            // Load the default config.
            keyfile.load_from_data("""
                [Namebar]
                only_max=false
                hide_icon=false
                hide_title=false
                hide_min=false
                hide_max=false
                hide_close=false
                align=1
                size=70
                expand=true
                active_bold=true
                passive_bold=true
                custom_colors=false
                active_color=#000000000000
                passive_color=#000000000000
                theme=
            """, -1, KeyFileFlags.NONE);
            // Load the keyfile.
        } catch {
            stderr.printf("The default config got messed up somehow...");
        }
        try {
            // Load the keyfile.
            keyfile.load_from_file(lookup_rc_file(), KeyFileFlags.NONE);
        } catch { }
        try {
            only_max = keyfile.get_boolean("Namebar", "only_max");
            size = keyfile.get_integer("Namebar", "size");
            expand = keyfile.get_boolean("Namebar", "expand");
            align = (uint8)keyfile.get_integer("Namebar", "align");
            active_bold = keyfile.get_boolean("Namebar", "active_bold");
            passive_bold = keyfile.get_boolean("Namebar", "passive_bold");
            hide_min = keyfile.get_boolean("Namebar", "hide_min");
            hide_max = keyfile.get_boolean("Namebar", "hide_max");
            hide_close = keyfile.get_boolean("Namebar", "hide_close");
            hide_icon = keyfile.get_boolean("Namebar", "hide_icon");
            hide_title = keyfile.get_boolean("Namebar", "hide_title");
            custom_colors = keyfile.get_boolean("Namebar", "custom_colors");
            string ac = keyfile.get_string("Namebar", "active_color");
            string pc = keyfile.get_string("Namebar", "passive_color");
            string theme_path = keyfile.get_string("Namebar", "theme");

            if (custom_colors) {
                active_color.parse(ac);
                passive_color.parse(pc);
            }
            theme = new Theme(File.new_for_path(theme_path));
        } catch {
            stdout.printf("Couldn't load configuration.\n");
        }

        // If no theme was loaded while loading configuration...
        if (theme == null || theme.valid == false) {
            // Look for the default theme.
            string[] dirs = Environment.get_system_data_dirs();
            dirs += Environment.get_user_data_dir();
            bool theme_loaded = false;
            for (uint8 i = 0; i < dirs.length && !theme_loaded; i++) {
                File tf = File.new_for_path(dirs[i]).get_child(
                  "namebar/themes/Default");
                if (tf.query_exists(null)) {
                    theme = new Theme(tf);
                    theme_loaded = theme.valid;
                }
            }

            // If it didn't load, show an error message.
            if (!theme_loaded) {
                MessageDialog md = new MessageDialog(null, 0, MessageType.ERROR,
                  ButtonsType.OK, "Failed to load default theme.");
                md.run();
                md.destroy();
            }
        }

        // Get wnck ready.
        shown_window = null;
        active_window = null;
        set_client_type(ClientType.PAGER);
        screen = Screen.get_default();
        screen.force_update();

        // Window icon.
        EventBox eb1 = new EventBox();
        eb1.visible_window = false;
        window_icon = new Image();
        eb1.add(window_icon);
        eb1.no_show_all = hide_icon;

        // Title label.
        EventBox eb2 = new EventBox();
        eb2.visible_window = false;
        title_label = new Label(null);
        title_label.set_alignment(align_float, 0.5f);
        title_label.ellipsize = EllipsizeMode.END;
        eb2.add(title_label);
        eb2.no_show_all = hide_title;

        // Minimize button.
        EventBox eb3 = new EventBox();
        eb3.visible_window = false;
        minimize_icon = new Image();
        eb3.add(minimize_icon);
        eb3.no_show_all = hide_min;

        // Maximize/Restore button.
        EventBox eb4 = new EventBox();
        eb4.visible_window = false;
        max_res_icon = new Image();
        eb4.add(max_res_icon);
        eb4.no_show_all = hide_max;

        // Close button.
        EventBox eb5 = new EventBox();
        eb5.visible_window = false;
        close_icon = new Image();
        eb5.add(close_icon);
        eb5.no_show_all = hide_close;

        // Create EventBox and the box. This is so the plugin
        // can still be configured even when the box is hidden.
        EventBox ebox = new EventBox();
        ebox.show();
        ebox.visible_window = false;
        box = new HBox(false, 0);
        box.spacing = 0;
        box.pack_start(eb1, false, false, 2);
        box.pack_start(eb2, true, true, 2);
        box.pack_start(eb3, false, false, 0);
        box.pack_start(eb4, false, false, 0);
        box.pack_start(eb5, false, false, 0);

        // Pack it all in.
        ebox.add(box);
        add(ebox);
        set_size_request(size > 0 ? size : -1, -1);
        set_expand(expand);

        // Connect signals.
        screen.active_window_changed.connect(active_window_changed);
        screen.window_closed.connect((s) => {
            if (s == shown_window) {
                find_window_to_show();
            }
        });
        eb3.enter_notify_event.connect(button_entered);
        eb3.leave_notify_event.connect(button_left);
        eb3.button_press_event.connect(button_pressed);
        eb3.button_release_event.connect(button_released);
        eb4.enter_notify_event.connect(button_entered);
        eb4.leave_notify_event.connect(button_left);
        eb4.button_press_event.connect(button_pressed);
        eb4.button_release_event.connect(button_released);
        eb5.enter_notify_event.connect(button_entered);
        eb5.leave_notify_event.connect(button_left);
        eb5.button_press_event.connect(button_pressed);
        eb5.button_release_event.connect(button_released);
        eb2.button_press_event.connect(title_clicked);
        eb1.button_press_event.connect(title_clicked);
        notify.connect(property_changed);
        menu_show_configure();
        configure_plugin.connect(() => {
            PrefDialog pd = new PrefDialog(this);
            pd.run();
            pd.destroy();
        });

        // Find a window to show.
        find_window_to_show();
    }


    ///////////////////
    // Functions
    ///////////////////

    // Refreshes the theme details and label attributes.
    private void refresh_attributes () {
        set_button_state(minimize_icon, ButtonState.NORMAL);
        set_button_state(max_res_icon, ButtonState.NORMAL);
        set_button_state(close_icon, ButtonState.NORMAL);
        bool active = shown_window.is_active();
        bool bold = (active ? active_bold : passive_bold);
        Color col = (active ? active_color : passive_color);
        AttrList al = new AttrList();
        al.insert(attr_foreground_new(col.red, col.green, col.blue));
        al.insert(attr_weight_new((bold ? Weight.BOLD : Weight.NORMAL)));
        title_label.set_attributes(al);
        title_label.set_alignment(align_float, 0.5f);
    }

    // Changes the currently shown window.
    private void set_shown_window (Wnck.Window new_win) {
        // We don't need the old window emitting events.
        if (shown_window != null) {
            shown_window.name_changed.disconnect(shown_name_changed);
            shown_window.icon_changed.disconnect(shown_icon_changed);
            shown_window.state_changed.disconnect(shown_state_changed);
        }

        // Set the window.
        shown_window = new_win;

        // Connect the new events.
        shown_window.name_changed.connect(shown_name_changed);
        shown_window.icon_changed.connect(shown_icon_changed);
        shown_window.state_changed.connect(shown_state_changed);

        // Reset attributes.
        shown_name_changed();
        shown_icon_changed();
        refresh_attributes();

        // Show everything in the box.
        box.show_all();
    }

    // Hides the namebar if there is no valid window.
    private void show_none () {
        // Disconnect the old window's events.
        if (shown_window != null) {
            shown_window.name_changed.disconnect(shown_name_changed);
            shown_window.icon_changed.disconnect(shown_icon_changed);
            shown_window.state_changed.disconnect(shown_state_changed);
        }

        // Set window to null.
        shown_window = null;

        // Hide everything in the box.
        box.hide_all();
    }

    // Finds a window to show.
    private void find_window_to_show () {
        // Check the active window if in active mode and set it if it fits.
        if (!only_max && active_window != null &&
          !active_window.is_skip_tasklist() &&
          (active_window.get_window_type() == Wnck.WindowType.NORMAL ||
          active_window.get_window_type() == Wnck.WindowType.DIALOG)) {
            set_shown_window(active_window);
            return;
        }

        // If in maximized mode, find the topmost window and set it.
        if (only_max) {
            // Get the list of stacked windows.
            unowned List<Wnck.Window> window_stack =
              screen.get_windows_stacked();

            // Iterate through in reverse.
            if (window_stack.length() > 1) {
                for (uint i = window_stack.length() - 1; i >= 1; i--) {
                    // Check the window, and if it fits, set it.
                    Wnck.Window w = window_stack.nth_data(i);
                    if (w.get_workspace() == screen.get_active_workspace() &&
                      w.is_maximized() &&
                      !w.is_minimized() &&
                      !w.is_skip_tasklist() &&
                      (w.get_window_type() == Wnck.WindowType.NORMAL ||
                      w.get_window_type() == Wnck.WindowType.DIALOG)) {
                        set_shown_window(w);
                        return;
                    }
                }
            }
        }

        // If we still don't have a window, set it to none.
        show_none();
    }

    // Sets the state of a button.
    private void set_button_state (Image img, ButtonState bs) {
        // Get stuff ready.
        bool active = shown_window.is_active();
        ThemeButton tb;

        // Determine which button we're on.
        if (img == minimize_icon) {
            tb = ThemeButton.MINIMIZE;
        } else if (img == close_icon) {
            tb = ThemeButton.CLOSE;
        } else {
            if (shown_window.is_maximized()) tb = ThemeButton.RESTORE;
            else tb = ThemeButton.MAXIMIZE;
        }

        // Set the pixbuf on the image.
        img.pixbuf = theme.get_pixbuf(active, tb, bs);
    }


    ///////////////////
    // Prop Notify
    ///////////////////

    // Emitted when a property changes.
    private void property_changed () {
        // Immediately reflect the changes.
        set_size_request(size > 0 ? size : -1, -1);
        set_expand(expand);
        title_label.set_alignment(align_float, 0.5f);

        // Set visibility of each element.
        EventBox eb = window_icon.parent as EventBox;
        eb.visible = !(eb.no_show_all = hide_icon);
        eb = title_label.parent as EventBox;
        eb.visible = !(eb.no_show_all = hide_title);
        eb = minimize_icon.parent as EventBox;
        eb.visible = !(eb.no_show_all = hide_min);
        eb = max_res_icon.parent as EventBox;
        eb.visible = !(eb.no_show_all = hide_max);
        eb = close_icon.parent as EventBox;
        eb.visible = !(eb.no_show_all = hide_close);

        // Go find the window, for posterity.
        find_window_to_show();

        // Save the properties to the keyfile.
        KeyFile keyfile = new KeyFile();
        try {
            keyfile.set_boolean("Namebar", "only_max", only_max);
            keyfile.set_boolean("Namebar", "hide_icon", hide_icon);
            keyfile.set_boolean("Namebar", "hide_title", hide_title);
            keyfile.set_boolean("Namebar", "hide_min", hide_min);
            keyfile.set_boolean("Namebar", "hide_max", hide_max);
            keyfile.set_boolean("Namebar", "hide_close", hide_close);
            keyfile.set_integer("Namebar", "size", size);
            keyfile.set_boolean("Namebar", "expand", expand);
            keyfile.set_integer("Namebar", "align", align);
            keyfile.set_boolean("Namebar", "active_bold", active_bold);
            keyfile.set_boolean("Namebar", "passive_bold", passive_bold);
            keyfile.set_boolean("Namebar", "custom_colors", custom_colors);
            keyfile.set_string("Namebar", "active_color",
              active_color.to_string());
            keyfile.set_string("Namebar", "passive_color",
              passive_color.to_string());
            keyfile.set_string("Namebar", "theme", theme.path);
            FileUtils.set_contents(save_location(true), keyfile.to_data(null));
        } catch {
            stdout.printf("Couldn't save configuration.\n");
        }
    }


    ///////////////////
    // Window Events
    ///////////////////

    // Emitted when the active window changes.
    private void active_window_changed () {
        // Disconnect state change event from old window.
        if (active_window != null) {
            active_window.state_changed.disconnect(active_state_changed);
        }

        // Set active window, check it, and reconnect the event.
        active_window = screen.get_active_window();
        if (active_window != null && !active_window.is_skip_tasklist() &&
          (active_window.get_window_type() == Wnck.WindowType.NORMAL ||
          active_window.get_window_type() == Wnck.WindowType.DIALOG)) {
            active_window.state_changed.connect(active_state_changed);
        }

        // For posterity, find a window to show.
        find_window_to_show();
    }

    // Emitted when the active window's state changes.
    private void active_state_changed () {
        // Prevent wnck assertion failure messages.
        if (active_window == null) {
            return;
        }

        // If the window was maximized and it's not
        // already the shown window, then show it.
        if (active_window != shown_window && active_window.is_maximized()) {
            set_shown_window(active_window);
        }
    }

    // Emitted when the shown window's name changes.
    private void shown_name_changed () {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return;
        }

        // Set title label and its tooltip.
        string name = shown_window.get_name();
        title_label.label = name;
        title_label.tooltip_text = name;
    }

    // Emitted when the shown window's icon changes.
    private void shown_icon_changed () {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return;
        }

        // Set the window icon's pixbuf.
        window_icon.pixbuf = shown_window.get_mini_icon();
    }

    // Emitted when the shown window's state changes.
    private void shown_state_changed () {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return;
        }

        // Change the max/res button.
        set_button_state(max_res_icon, ButtonState.NORMAL);

        // Determine if a new window needs to be found.
        if ((only_max && !shown_window.is_maximized()) ||
          shown_window.is_minimized()) {
            find_window_to_show();
        }
    }


    ///////////////////
    // Widget Events
    ///////////////////

    // Changes the icon once a button is entered.
    private bool button_entered (Widget sender, Gdk.EventCrossing ec) {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return false;
        }

        Image img = (sender as EventBox).child as Image;
        set_button_state(img, ButtonState.HOVER);
        return true;
    }

    // Changes the icon once a button is left.
    private bool button_left (Widget sender, Gdk.EventCrossing ec) {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return false;
        }

        Image img = (sender as EventBox).child as Image;
        set_button_state(img, ButtonState.NORMAL);
        return true;
    }


    // Changes the icon once a button is pressed.
    private bool button_pressed (Widget sender, Gdk.EventButton event) {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return false;
        }

        if (event.button == 1) {
            Image img = (sender as EventBox).child as Image;
            set_button_state(img, ButtonState.PRESSED);
        }
        return true;
    }

    // Performs an action when an button is released.
    private bool button_released (Widget sender, Gdk.EventButton event) {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return false;
        }

        // Preparation for below check.
        int x, y;
        sender.get_pointer(out x, out y);
        Allocation a = sender.allocation;

        // Abort method if the main button wasn't released
        // inside the event box.
        if (x < 0 || y < 0 || x > a.width || y > a.height ||
          event.button != 1) {
            return false;
        }

        // Determine what to do based on which icon was
        // clicked and do it.
        Image img = (sender as EventBox).child as Image;
        if (img == minimize_icon) {
            shown_window.minimize();
        } else if (img == close_icon) {
            shown_window.close(event.time);
        } else if (img == max_res_icon) {
            if (shown_window.is_maximized()) {
                shown_window.unmaximize();
            } else {
                shown_window.maximize();
            }
        }

        // Set the button state to normal.
        set_button_state(img, ButtonState.NORMAL);
        return true;
    }

    // Focuses the window when the title label is clicked.
    private bool title_clicked (Widget sender, Gdk.EventButton event) {
        // Prevent wnck assertion failure messages.
        if (shown_window == null) {
            return false;
        }

        // Preparation for below check.
        int x, y;
        sender.get_pointer(out x, out y);
        Allocation a = sender.allocation;

        // Abort method if the main button wasn't released
        // inside the event box.
        if (x < 0 || y < 0 || x > a.width ||
         y > a.height || event.button != 1) {
            return false;
        }

        // Focus the window.
        shown_window.activate(event.time);
        return true;
    }

}
