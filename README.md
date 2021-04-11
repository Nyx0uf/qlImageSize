![License: BSD](https://img.shields.io/badge/license-BSD-blue.svg?style=flat) [![Build Status](https://travis-ci.com/Nyx0uf/qlImageSize.svg?branch=master)](https://travis-ci.com/Nyx0uf/qlImageSize)

This project is composed of both a **QuickLook** plugin and a **Spotlight** plugin. Both are independant and can be built separately.
They require at least *macOS High Sierra (10.13)*.

# qlImageSize

This is the **QuickLook** plugin, it displays the dimensions, DPI and file size of an image in the title bar.

![https://static.whine.fr/images/2014/qlimagesize4.jpg](https://static.whine.fr/images/2019/qlimagesize1.jpg)

This plugin can also preview and generate *Finder* thumbnails for natively unsupported images formats [bpg](http://bellard.org/bpg/ "bpg") and  [WebP](https://developers.google.com/speed/webp/ "WebP").

![https://static.whine.fr/images/2014/qlimagesize3.jpg](https://static.whine.fr/images/2014/qlimagesize3.jpg)

![https://static.whine.fr/images/2014/qlimagesize2.jpg](https://static.whine.fr/images/2014/qlimagesize2.jpg)


# mdImageSize

This is the **Spotlight** plugin, it displays informations of unsupported images (**WebP**, **bpg**) in the Finder's inspector window.

![https://static.whine.fr/images/2014/mdimagesize1.jpg](https://static.whine.fr/images/2014/mdimagesize1.jpg)


# Install

3 choices :

1. Using [Homebrew Cask](https://brew.sh/): 
    ```
    brew install --cask qlimagesize mdimagesizemdimporter
    ```
2. Download the latest build from https://github.com/Nyx0uf/qlImageSize/releases/latest and save it to your `~/Library/QuickLook` and/or `~/Library/Spotlight` folder.
3. Build from sources using Xcode. (just have to hit the build button).


# Uninstall

2 choices :

1. Using [Homebrew Cask](https://brew.sh/):
    ```
    brew uninstall --cask qlimagesize mdimagesizemdimporter
    ```
2. Manually :
    - Launch *Terminal.app* in `/Applications/Utilities`
    - Copy and paste the following line:
		```
		rm -rf ~/Library/QuickLook/qlImageSize.qlgenerator ~/Library/Spotlight/mdImageSize.mdimporter
		```
    - Press <kbd>Enter</kbd>.


# Limitations

If you are a **Pixelmator** user, its own QuickLook plugin might get in the way when previewing **WebP** files. To fix this you need to edit the file `/Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/Info.plist` and remove the dict entry that handles **webp**.

After editing the `Info.plist`, QuickLook for the Pixelmator file format (such as `.pxm`) might not work due to Code Signing. You can unsign Pixelmator's QuickLook binary using the tool [unsign](https://github.com/steakknife/unsign). After downloading and building it, just run :

	unsign /Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/MacOS/PixelmatorLook`.

It will create another binary with the extension **unsigned**, rename the orignal binary for backup then remove the extension for the unsigned binary, ex :

	mv /Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/MacOS/PixelmatorLook /Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/MacOS/PixelmatorLook.bak
	mv /Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/MacOS/PixelmatorLook.unsigned /Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/MacOS/PixelmatorLook


# Upgrading dependencies

### libwbep

Grab the [latest version](https://github.com/webmproject/libwebp/releases). Decompress the archive and simply run :

	./autogen.sh
	CFLAGS="-mmacosx-version-min=10.13" ./configure --disable-shared
	make

The resulting library can be found in *src/.libs/libwebp.a*.

### libbpg

Grab the [latest version](https://bellard.org/bpg/). Decompress the archive and edit the `Makefile` with the following changes :

- Uncomment the line which reads `CONFIG_APPLE=y`
- Comment both lines `USE_X265=y` and `USE_BPGVIEW=y`

And replace the following

	ifdef CONFIG_APPLE
	LDFLAGS+=-Wl,-dead_strip

with 

	ifdef CONFIG_APPLE
	LDFLAGS+=-Wl,-dead_strip
	CFLAGS+=-mmacosx-version-min=10.13

Then simply run `make`. The resulting library will be in the project directory.

# License

This project is released under the *MIT license*, see **LICENSE**.
