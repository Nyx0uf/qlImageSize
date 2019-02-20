![License: BSD](https://img.shields.io/badge/license-BSD-blue.svg?style=flat) [![Build Status](https://travis-ci.com/Nyx0uf/qlImageSize.svg?branch=master)](https://travis-ci.com/Nyx0uf/qlImageSize)

# qlImageSize

This is a **QuickLook** plugin for OS X *10.11+* to display the dimensions of an image and its file size in the title bar.

![https://static.whine.fr/images/2014/qlimagesize4.jpg](https://static.whine.fr/images/2014/qlimagesize4.jpg)

This plugin can also preview and generate Finder thumbnails for unsupported images formats like :

- [bpg](http://bellard.org/bpg/ "bpg")
- [WebP](https://developers.google.com/speed/webp/ "WebP")

![https://static.whine.fr/images/2014/qlimagesize3.jpg](https://static.whine.fr/images/2014/qlimagesize3.jpg)

![https://static.whine.fr/images/2014/qlimagesize2.jpg](https://static.whine.fr/images/2014/qlimagesize2.jpg)


# mdImageSize

It's a **Spotlight** plugin to display informations of unsupported images (**WebP**, **bpg**, **Portable Pixmap**) in the Finder's inspector window.

![https://static.whine.fr/images/2014/mdimagesize1.jpg](https://static.whine.fr/images/2014/mdimagesize1.jpg)


### Installation

3 choices : 

- Via [Homebrew Cask](https://brew.sh/): `brew cask install qlimagesize`
- Download manually the latest build from https://github.com/Nyx0uf/qlImageSize/releases/tag/1.6.1 and save it to the `~/Library/QuickLook` folder
- Build from sources using Xcode. (just have to hit the build button)

### Uninstall

- Via [Homebrew Cask](https://brew.sh/): `brew cask install qlimagesize`
- Manually:
  - Launch Terminal.app (in `/Applications/Utilities`)
  - Copy and paste the following line into the Terminal :

    `sudo rm -rf "/Library/Application Support/qlimagesize" "~/Library/QuickLook/qlImageSize.qlgenerator" "~/Library/Spotlight/mdImageSize.mdimporter"`

  - Press Enter.
  - Type your password and press Enter.

### Limitations

If you are a **Pixelmator** user, its own QuickLook plugin might get in the way when previewing **WebP** files. To fix this you need to edit the file `/Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/Info.plist` and remove the dict entry that handles **webp**.

After editing the `Info.plist`, the QuickLook for Pixelmator file format (such as `.pxm`) might not work due to Code Signing, you can unsign the Pixelmator's QuickLook binary using this tool, [unsign](https://github.com/steakknife/unsign). After downloading and `make` the tool, unsign the binary inside `MacOS/` , it will create another binary with the extension `unsigned`, rename the orignal binary for backup then remove the extension for the unsigned binary.

`./unsign /Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/MacOS/PixelmatorLook`

### License

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE**.
