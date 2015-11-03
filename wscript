#!/usr/bin/env python
#
# Copyright (c) 2010 Trent McPheron <twilightinzero@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# For creating a source archive.
APPNAME = 'xfce4-namebar-plugin'
VERSION = '0.3.3'

# Required waf stuff.
top = '.'
out = 'build'

def options (ctx):
	ctx.load('compiler_c')
	ctx.load('vala')

def configure (ctx):
	# Strip extraneous slash from prefix.
	if ctx.options.prefix[-1] == '/' :
		ctx.options.prefix += ctx.options.prefix[-1]
	
	# Check for required stuff.
	ctx.load('compiler_c misc')
	ctx.load('vala', funs='')
	ctx.check_vala(min_version=(0, 12, 0), branch=(0, 12))
	args = '--cflags --libs'
	ctx.check_cfg(package = 'glib-2.0', atleast_version = '2.10',
		uselib_store = 'GLIB', mandatory = True, args = args)
	ctx.check_cfg(package = 'gtk+-2.0', atleast_version = '2.16',
		uselib_store = 'GTK', mandatory = True, args = args)
	ctx.check_cfg(package = 'libxfce4panel-1.0', atleast_version = '4.6',
		uselib_store = 'XFCE4PANEL', mandatory = True, args = args)
	ctx.check_cfg(package = 'libwnck-1.0', atleast_version = '2.20',
		uselib_store = 'LIBWNCK', mandatory = True, args = args)

def build (ctx):
	# Compile the program.
	ctx.program(
		features     = 'c cshlib',
		is_lib       = True,
		vapi_dirs    = 'vapi',
		source       = ctx.path.ant_glob('src/*'),
		packages     = 'glib-2.0 gtk+-2.0 libxfce4panel-1.0 libwnck-1.0',
		target       = 'namebar',
		install_path = '${PREFIX}/lib/xfce4/panel/plugins/',
		uselib       = 'GLIB GTK XFCE4PANEL LIBWNCK',
		defines      = ['WNCK_I_KNOW_THIS_IS_UNSTABLE'])
	
	# Substitute the prefix in the desktop file.
	ctx(
		features = 'subst',
		source = 'data/namebar.desktop.in',
		target = 'data/namebar.desktop')
	
	# Install the files.
	data_dir = ctx.path.find_dir('data')
	ctx.install_files(
		'${PREFIX}/share/namebar/',
		data_dir.ant_glob('themes/**/*'),
		cwd = data_dir,
		relative_trick = True)
	ctx.install_files(
		'${PREFIX}/share/xfce4/panel-plugins/',
		'data/namebar.desktop')
	ctx.install_files(
		'${PREFIX}/share/pixmaps/',
		'data/xfce4-namebar.png')
	ctx.install_files(
		'${PREFIX}/bin/',
		'data/convert-wb-to-nb',
		chmod=0o755)

def checkinstall (ctx):
    ctx.exec_command('checkinstall --pkgname=' + APPNAME +
     ' --pkgversion=' + VERSION + ' --provides=' + APPNAME +
     ' --deldoc=yes --deldesc=yes --delspec=yes --backup=no' +
     ' --exclude=/home -y ./waf install')
