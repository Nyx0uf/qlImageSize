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

- Download the `.pkg` installer [here](https://repo.whine.fr/qlImageSize.pkg "qlImageSize for 10.9+").
- Open it.
- Follow the steps. (you will be asked for an admin password)


### Uninstall

- Launch Terminal.app (in `/Applications/Utilities`)
- Copy and paste the following line into the Terminal :

`sudo rm -rf "/Library/Application Support/qlimagesize" "~/Library/QuickLook/qlImageSize.qlgenerator" "~/Library/Spotlight/mdImageSize.mdimporter"`

- Press Enter.
- Type your password and press Enter.


### Limitations

If you are a **Pixelmator** user, its own QuickLook plugin might get in the way when previewing **WebP** files. To fix this you need to edit the file `/Applications/Pixelmator.app/Contents/Library/QuickLook/PixelmatorLook.qlgenerator/Contents/Info.plist` and remove the dict entry that handles **webp**.


### License

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE**.

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf "Nyx0uf on Twitter")
