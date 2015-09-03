# qlImageSize

This is a **QuickLook** plugin for OS X *10.8+* to display the dimensions of an image and its file size in the title bar.

![qlImageSize preview window](https://static.whine.fr/images/2014/qlimagesize4.jpg)

This plugin can also preview and generate Finder thumbnails for unsupported images formats like :

- [bpg](http://bellard.org/bpg/ "bpg")
- [Portable Pixmap](http://en.wikipedia.org/wiki/Netpbm_format "Netpbm")
- [WebP](https://developers.google.com/speed/webp/ "WebP")

![qlImageSize thumbnails generation](https://static.whine.fr/images/2014/qlimagesize3.jpg)

![qlImageSize WebP and PPM preview](https://static.whine.fr/images/2014/qlimagesize2.jpg)


# mdImageSize

It's a **Spotlight** plugin to display informations of unsupported images (**WebP**, **bpg**, **Portable Pixmap**) in the Finder's inspector window.

![mdImageSize](https://static.whine.fr/images/2014/mdimagesize1.jpg)


### Installation

- Download the `.pkg` installer [here](https://repo.whine.fr/qlImageSize.pkg "qlImageSize for 10.8+").
- Open it.
- Follow the steps. (you will be asked for an admin password)


### Uninstall

- Launch Terminal.app (in `/Applications/Utilities`)
- Copy and paste the following line into the Terminal :

	sudo rm -rf "/Library/Application Support/qlimagesize" "/Library/QuickLook/qlImageSize.qlgenerator" "/Library/Spotlight/mdImageSize.mdimporter"

- Press Enter.
- Type your password and press Enter.


### Limitations

If you are a **Pixelmator** user, its own QuickLook plugin might get in the way when previewing **WebP** files. To fix this you need to edit the file `/Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/Info.plist` and remove the dict entry that handles **webp**.


### License

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE**.

Blog : [Cocoa in the Shell](http://cocoaintheshell.com "Cocoa in the Shell")

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf "Nyx0uf on Twitter")

---

### About Mavericks (OS X 10.9)

***qlImageSize*** doesn't fully work on 10.9. By fully, I mean it works for certain types of images like *tga*, *bmp*, *psd*, *tif* but not for the common ones *jpg*, *png*, *gif*.

It is a known bug in the OS and I can't do anything about it, Apple never fixed it and won't. The best way is to update to this ugly as fuck 10.10, how sad.

For more informations, see [issue 4](https://github.com/Nyx0uf/qlImageSize/issues/4 "issue 4").
