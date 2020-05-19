// Copyright (c) 2010 Trent McPheron <twilightinzero@gmail.com>
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

using Gtk;


///////////////////
// Pref. Dialog
///////////////////

class PrefDialog : Dialog {

    ///////////////////
    // Fields
    ///////////////////

    private NamebarPlugin namebar;
    private List<Theme>   themes;
    private RadioButton   active_radio;
    private RadioButton   max_radio;
    private CheckButton   icon_check;
    private CheckButton   title_check;
    private CheckButton   min_check;
    private CheckButton   max_check;
    private CheckButton   close_check;
    private SpinButton    size_spin;
    private CheckButton   expand_check;
    private ComboBoxText  align_combo;
    private ComboBoxText  theme_combo;
    private CheckButton   custom_check;
    private ColorButton   active_color;
    private ColorButton   passive_color;
    private CheckButton   active_check;
    private CheckButton   passive_check;


    ///////////////////
    // Constructor
    ///////////////////

    public PrefDialog (NamebarPlugin namebar) {
        // Set preliminary stuff.
        title = "Namebar Preferences";
        this.namebar = namebar;
        response.connect(() => {
            dispose();
        });

        // Now let's make some widgets.
        unowned Box content = get_content_area() as Box;
        content.spacing = 8;

        // Title settings.
        var title_box = new Box(Orientation.VERTICAL, 0);
        var title_label = new Label("<big>Show window title</big>");
        title_label.set_alignment(0.0f, 0.5f);
        title_label.use_markup = true;
        active_radio = new RadioButton.with_label(null, "Active window");
        max_radio = new RadioButton.with_label_from_widget(
          active_radio, "Top maximized window");
        title_box.pack_start(title_label, false, false, 0);
        title_box.pack_start(active_radio, false, false, 0);
        title_box.pack_start(max_radio, false, false, 0);
        content.pack_start(title_box, false, false, 0);

        // Maximize/Restore button settings.
        var hide_box = new Box(Orientation.VERTICAL, 0);
        var hide_label = new Label("<big>Hide Namebar elements</big>");
        hide_label.set_alignment(0.0f, 0.5f);
        hide_label.use_markup = true;
        icon_check = new CheckButton.with_label("Icon");
        title_check = new CheckButton.with_label("Title");
        min_check = new CheckButton.with_label("Minimize");
        max_check = new CheckButton.with_label("Maximize/Restore");
        close_check = new CheckButton.with_label("Close");
        hide_box.pack_start(hide_label, false, false, 0);
        hide_box.pack_start(icon_check, false, false, 0);
        hide_box.pack_start(title_check, false, false, 0);
        hide_box.pack_start(min_check, false, false, 0);
        hide_box.pack_start(max_check, false, false, 0);
        hide_box.pack_start(close_check, false, false, 0);
        content.pack_start(hide_box, false, false, 0);

        // Size settings.
        var size_box = new Box(Orientation.HORIZONTAL, 2);
        var size_label = new Label("Size:");
        var adj = new Adjustment(0, -1, 2000, 1, 50, 0);
        size_spin = new SpinButton(adj, 0.5, 0);
        expand_check = new CheckButton.with_label("Expand");
        size_box.pack_start(size_label, false, false, 0);
        size_box.pack_start(size_spin, false, false, 0);
        size_box.pack_start(expand_check, false, false, 0);
        content.pack_start(size_box, false, false, 0);
        var align_box = new Box(Gtk.Orientation.HORIZONTAL, 2);
        Label align_label = new Label("Align:");
        align_combo = new ComboBoxText();
        align_combo.append_text("Left");
        align_combo.append_text("Center");
        align_combo.append_text("Right");
        align_box.pack_start(align_label, false, false, 0);
        align_box.pack_start(align_combo, false, false, 0);
        content.pack_start(align_box, false, false, 0);

        // Theme settings.
        var theme_box = new Box(Orientation.HORIZONTAL, 2);
        var theme_label = new Label("Theme:");
        theme_combo = new ComboBoxText();
        themes = find_themes();
        for (uint8 i = 0; i < themes.length(); i++) {
            theme_combo.append_text(themes.nth_data(i).name);
            if (namebar.theme.name == themes.nth_data(i).name) {
                theme_combo.active = i;
            }
        }
        theme_box.pack_start(theme_label, false, false, 0);
        theme_box.pack_start(theme_combo, false, false, 0);
        content.pack_start(theme_box, false, false, 0);

        // Color settings.
        custom_check = new CheckButton.with_label("Custom colors");
        content.pack_start(custom_check, false, false, 0);
        var color_grid = new Grid();
        var active_label = new Label("Active color:");
        active_label.set_alignment(0.0f, 0.5f);
        active_color = new ColorButton();
        var active_reset = new Button();
        active_reset.add(new Image.from_icon_name("clear", IconSize.BUTTON));
        active_check = new CheckButton.with_label("Bold");
        var passive_label = new Label("Passive color:");
        passive_label.set_alignment(0.0f, 0.5f);
        passive_color = new ColorButton();
        var passive_reset = new Button();
        passive_reset.add(new Image.from_icon_name("clear", IconSize.BUTTON));
        passive_check = new CheckButton.with_label("Bold");
        color_grid.attach(active_label, 0, 1);
        color_grid.attach(active_color, 1, 1);
        color_grid.attach(active_reset, 2, 1);
        color_grid.attach(active_check, 3, 1);
        color_grid.attach(passive_label, 0, 2);
        color_grid.attach(passive_color, 1, 2);
        color_grid.attach(passive_reset, 2, 2);
        color_grid.attach(passive_check, 3, 2);
        content.pack_start(color_grid, false, false, 0);

        // Get current settings.
        active_radio.active = !namebar.only_max;
        max_radio.active = namebar.only_max;
        icon_check.active = namebar.hide_icon;
        title_check.active = namebar.hide_title;
        min_check.active = namebar.hide_min;
        max_check.active = namebar.hide_max;
        close_check.active = namebar.hide_close;
        size_spin.value = namebar.nb_size;
        expand_check.active = namebar.nb_expand;
        align_combo.active = namebar.align;
        custom_check.active = namebar.custom_colors;
        active_check.active = namebar.active_bold;
        passive_check.active = namebar.passive_bold;
        //var color = Gdk.RGBA();
        //color.red = namebar.active_color.red;
        //color.green = namebar.active_color.green;
        //color.blue = namebar.active_color.blue;
        //active_color.rgba = color;
        //color.red = namebar.passive_color.red;
        //color.green = namebar.passive_color.green;
        //color.blue = namebar.passive_color.blue;
        //passive_color.rgba = color;
        active_color.rgba = namebar.active_color;
        passive_color.rgba = namebar.passive_color;

        // Lambda functions for all the signals.
        active_radio.toggled.connect(() => {
            namebar.only_max = !active_radio.active;
        });
        max_radio.toggled.connect(() => {
            namebar.only_max = max_radio.active;
        });
        icon_check.toggled.connect(() => {
            namebar.hide_icon = icon_check.active;
        });
        title_check.toggled.connect(() => {
            namebar.hide_title = title_check.active;
        });
        min_check.toggled.connect(() => {
            namebar.hide_min = min_check.active;
        });
        max_check.toggled.connect(() => {
            namebar.hide_max = max_check.active;
        });
        close_check.toggled.connect(() => {
            namebar.hide_close = close_check.active;
        });
        size_spin.value_changed.connect(() => {
            namebar.nb_size = (int)size_spin.value;
        });
        expand_check.toggled.connect(() => {
            namebar.nb_expand = expand_check.active;
        });
        theme_combo.changed.connect(() => {
            namebar.theme = themes.nth_data(theme_combo.active);
        });
        align_combo.changed.connect(() => {
            namebar.align = (uint8)align_combo.active;
        });
        custom_check.toggled.connect(() => {
            namebar.custom_colors = custom_check.active;
            if (namebar.custom_colors) {
                //var new_color = Gdk.RGBA();
                //new_color.red = active_color.rgba.red;
                //new_color.green = active_color.rgba.green;
                //new_color.blue = active_color.rgba.blue;
                //namebar.active_color = new_color;
                //new_color.red = passive_color.rgba.red;
                //new_color.green = passive_color.rgba.green;
                //new_color.blue = passive_color.rgba.blue;
                //namebar.passive_color = new_color;
                namebar.active_color = active_color.rgba;
                namebar.passive_color = passive_color.rgba;
            } else {
                namebar.active_color = namebar.active_default;
                namebar.passive_color = namebar.passive_default;
            }
        });
        active_color.color_set.connect(() => {
            //var new_color = Gdk.RGBA();
            //new_color.red = active_color.rgba.red;
            //new_color.green = active_color.rgba.green;
            //new_color.blue = active_color.rgba.blue;
            var new_color = active_color.rgba;
            if (namebar.custom_colors) namebar.active_color = new_color;
        });
        passive_color.color_set.connect(() => {
            //var new_color = Gdk.RGBA();
            //new_color.red = passive_color.rgba.red;
            //new_color.green = passive_color.rgba.green;
            //new_color.blue = passive_color.rgba.blue;
            var new_color = passive_color.rgba;
            if (namebar.custom_colors) namebar.passive_color = new_color;
        });
        active_reset.clicked.connect(() => {
            namebar.active_color = namebar.active_default;
            namebar.passive_color = namebar.passive_default;
        });
        active_check.toggled.connect(() => {
            namebar.active_bold = active_check.active;
        });
        passive_check.toggled.connect(() => {
            namebar.passive_bold = passive_check.active;
        });

        // Finish up.
        add_button("Close", ResponseType.CLOSE);
        show_all();
    }


    ///////////////////
    // Functions
    ///////////////////

    // Find all the themes on the system.
    private List<Theme> find_themes () {
        List<Theme> list = new List<Theme>();

        // Get all the candidate dirs ready.
        string[] dir_strings = Environment.get_system_data_dirs();
        dir_strings += Environment.get_user_data_dir();
        File[] dirs = new File[dir_strings.length];

        // Iterate through each directory to load its themes.
        for (uint8 i = 0; i < dirs.length; i++) {
            // Create the file object for the theme subdirectory.
            dirs[i] = File.new_for_path(dir_strings[i]).get_child("namebar/themes");

            // If the directory exists, search it for themes.
            if (dirs[i].query_exists(null)) {
                try {
                    // Get an enumerator for the directory.
                    FileEnumerator enumerator = dirs[i].enumerate_children(
                      FileAttribute.STANDARD_NAME, 0, null);

                    // Iterate through all the children and try to
                    // load the themes in each. If successful, add
                    // them to the theme list.
                    FileInfo next_file;
                    while ((next_file = enumerator.next_file(null)) != null) {
                        File tdir = dirs[i].get_child(next_file.get_name());
                        if (tdir.query_file_type(0, null) == FileType.DIRECTORY) {
                            Theme theme = new Theme(tdir);
                            var unique = true;
                            foreach (Theme t in list) {
                                unique &= theme.name != t.name;
                            }
                            if (theme.valid && unique) {
                                list.append(theme);
                            }
                        }
                    }
                } catch {
                    stdout.printf("Something went horribly wrong.");
                }
            }
        }

        // If the theme list is empty, let the user know.
        if (list.length() == 0) {
            stdout.printf("There are no valid themes.");
        }

        // Sort the list.
        list.sort((CompareFunc)sort_themes);

        // Return the list.
        return list;
    }

    // For sorting the list.
    public static int sort_themes (Theme theme1, Theme theme2) {
        if (theme1.name > theme2.name) {
            return 1;
        } else if (theme2.name > theme1.name) {
            return -1;
        } else return 0;
    }

}
