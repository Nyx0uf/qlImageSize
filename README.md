# qlImageSize

This is a **QuickLook** plugin for OS X *10.8+* to display the dimensions of an image and its file size in the title bar.

For more detailed and technical informations see my [blog post about it](http://www.cocoaintheshell.com/2012/02/quicklook-images-dimensions/ "Images dimensions in QuickLook").

This plugin also displays non-standard image formats like :

- [WebP](https://developers.google.com/speed/webp/ "WebP")
- [Portable Pixmap](http://en.wikipedia.org/wiki/Netpbm_format "Netpbm")
- [bpg](http://bellard.org/bpg/ "bpg")

In order to handle **WebP** and **bpg**, you must install the libraries, the easiest way is using [Homebrew](http://brew.sh "Homebrew") :

	> brew install webp libbpg


If you are a **Pixelmator** user, its own *QuickLook* plugin might get in the way. To fix this you need to edit the file `/Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/Info.plist` and remove the dict entry that handles **webp**.

![qlImageSize in action](http://static.whine.fr/images/2014/qlimagesize1.jpg)

![qlImageSize WebP & PPM preview](http://static.whine.fr/images/2014/qlimagesize2.jpg)


### Installation

Download the plugin [here](http://repo.whine.fr/qlImageSize.qlgenerator-10.8.zip "qlImageSize for 10.8+").

Unzip it, and place it in `/Library/QuickLook` or `~/Library/QuickLook`.

You will need to restart the *QuickLook daemon* by running these commands in the Terminal :

	> qlmanage -r
	> qlmanage -r cache


### License

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE**.

Blog : [Cocoa in the Shell](http://www.cocoaintheshell.com "Cocoa in the Shell")

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf "Nyx0uf on Twitter")

---

### About Mavericks (OS X 10.9)

**qlImageSize** doesn't fully work on 10.9. By fully, I mean it works for certain types of images like *tga*, *bmp*, *psd*, *tif* but not for the common ones *jpg*, *png*, *gif*.

It is a known bug in the OS and I can't do anything about it, Apple never fixed it and won't. The best way is to update to this ugly as fuck 10.10, how sad.

For more informations, see [issue 4](https://github.com/Nyx0uf/qlImageSize/issues/4 "issue 4").
