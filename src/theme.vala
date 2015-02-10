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

using Gdk;


///////////////////
// Theme
///////////////////

public class Theme : Object {

    ///////////////////
    // Fields / Props
    ///////////////////

    public  bool     valid { get; set; default = true; }
    public  string   name  { get; set; }
    public  string   path  { get; set; }
    private Pixbuf[] pixbufs;


    ///////////////////
    // Constructor
    ///////////////////

    // Loads a theme from a directory.
    public Theme (File dir) {
        // Set properties and fields.
        name = dir.get_basename();
        path = dir.get_path();
        pixbufs = new Pixbuf[24];

        // First check if the dir exists.
        if (!dir.query_exists(null)) {
            // Invalid, obviously.
            printerr(@"The directory $(dir.get_path()) doesn't exist.\n");
            valid = false;
        }

        // Create arrays for buttons to load.
        string[] win_states = { "active", "passive" };
        string[] buttons    = { "minimize", "maximize", "restore", "close" };
        string[] but_states = { "normal", "prelight", "pressed" };

        // Iterate through each button and load it.
        for (uint8 a = 0; a < 2; a++)
        for (uint8 b = 0; b < 4; b++)
        for (uint8 c = 0; c < 3; c++) {
            // Create file object for the current image.
            File buf_file = dir.get_child(win_states[a]).get_child(buttons[b] +
              "_" + but_states[c] + ".png");

            // Create index based on position in loop.
            uint8 i = (a * 12) + (b * 3) + c;

            try {
                // Try loading it into a pixbuf.
                InputStream stream = buf_file.read(null);
                pixbufs[i] = new Pixbuf.from_stream(stream, null);
            } catch {
                // If we're on restore, try loading maximize.
                if (b == 2) {
                    // Recreate file object.
                    File new_buf_file = dir.get_child(win_states[a]).get_child(
                      buttons[b - 1] + "_" + but_states[c] + ".png");

                    try {
                        // Let's try again.
                        InputStream new_stream = new_buf_file.read(null);
                        pixbufs[i] = new Pixbuf.from_stream(new_stream, null);
                    } catch {
                        // Still didn't work...
                        printerr(@"Can't read $(buf_file.get_path()) " +
                          @"or $(new_buf_file.get_path())\n");
                        valid = false;
                    }
                } else {
                    // Didn't work...
                    printerr(@"Can't read $(buf_file.get_path())\n");
                    valid = false;
                }
            }
        }
    }


    ///////////////////
    // Functions
    ///////////////////

    // Gets a pixbuf from the loaded theme.
    public Pixbuf get_pixbuf (bool active, ThemeButton tb, ButtonState bs) {
        // Create the index.
        uint8 i = (active ? 0 : 12) + tb + bs;
        return pixbufs[i];
    }

}


///////////////////
// Enums
///////////////////

public enum ThemeButton {
    MINIMIZE = 0,
    MAXIMIZE = 3,
    RESTORE = 6,
    CLOSE = 9
}

public enum ButtonState {
    NORMAL = 0,
    HOVER = 1,
    PRESSED = 2
}
