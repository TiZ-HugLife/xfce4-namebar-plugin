# xfce4-namebar-plugin
### ver. 1.0.0

## About xfce4-namebar-plugin

xfce4-namebar-plugin is a Vala/Xfce4 port of the gnome-panel Namebar applet. Unlike xfce4-dockbarx-plugin, this is a straight port instead of a hack to integrate the pre-existing applet. This port has all of the functionality of the original Namebar, and then some. Configuration and theming work mostly the same way.

This is a really old port. I abandoned it when I stopped using it, and then windowck-plugin came out in the interim. It has a few problems, though. Namely, it is not friendly to translucent panels whatsoever, and its window detection is kind of spotty. So when I started using a workflow that put the window controls into the panel, I resurrected this project. I wouldn't mind letting this die if the problems in windowck-plugin get fixed. I also don't mind continuing development on it if people like it since it's not nearly as hacky as dbx had to be.

## Using xfce4-namebar-plugin

The configuration does not use gconf; it uses the .rc file functionality provided by xfce4-panel. You can hide each element of the namebar individually. By creating two namebars, you can replicate Window Applets's functionality. When using a button-less namebar, select the None theme to conserve memory.

As for themes, they must not remain in tarballs, unlike the original Namebar. This could be seen as a limitation. I couldn't find a way to load tarballs directly without bending over backwards. So they must be extracted to ${XDG_DATA_HOME}/namebar/themes/<theme name>. XDG_DATA_HOME is typically set to ~/.local/share. User-installed theme location is another difference from vanilla Namebar.

## Any extras?

All of the themes that came with Namebar come with this, and they will be installed to <prefix>/share/namebar/themes. A script is also included to convert Window Buttons themes to Namebar. Just run convert-wb-to-nb without any arguments to see how to use it.

## Okay, I'm sold! Gimme the goods!

Nobody has it packaged yet as far as I know. I just kind of threw it up on the internet a long time ago and never touched it again until now. Let me know if you package it by filing an issue to get it mentioned in the readme.

So until packages start to appear, you get to install from source. You need the following dependencies and their development files:

* Vala >= 0.12
* GLib >= 2.62
* GTK+3 >= 3.24
* Xfce4-Panel >= 4.12
* Libwnck >= 3.24

To configure, build, and install, run these commands:

    ./waf configure
    ./waf build
    sudo ./waf install

The panel will probably not detect the plugin unless you install it in the /usr prefix, and you probably have to adjust the library directory too, so using Xubuntu 18.04 as an example, do the configure step with `./waf configure --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu`

If you are using a distribution that supports checkinstall, you can replace the install step with `sudo ./waf checkinstall` to install it in your package manager.

## Awesome! Who do I need to thank for all this?

* Matias Särs is the original Namebar developer.
* The included Vala bindings were developed by Mike Masonnet.
* The developers of the Vala language are to be thanked, of course.
* The build system is waf, so all the guys working on that are to thank for keeping this out of autohell.
* Trent McPheron is the original developer of this xfce4-panel plugin.
* And the github community to whom I entrust the future of this plugin.

## I want to make the plugin better!

Awesome! Fork the repo and send me pull requests! I will probably merge any request I get.
