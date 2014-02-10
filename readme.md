# qlImageSize #

This is a *QuickLook* plugin for Mac OS X *10.7* / *10.8* to display the dimensions of an image and its file size in the title bar.

Since *10.8* iPhone's PNG are correctly displayed in the Finder, but before they were not, so in *10.7* this plugin also correctly display them.

for more informations see my [blog post about it](http://www.cocoaintheshell.com/2012/02/quicklook-images-dimensions/ "Images dimensions in QuickLook").


### Build & Install ###

For those who don't want to build from the sources, here are the links for the plugin: [Lion (10.7)](http://repo.whine.fr/qlImageSize.qlgenerator-10.7.zip) [Moutain Lion (10.8)](http://repo.whine.fr/qlImageSize.qlgenerator-10.8.zip) 

Unzip it, and place it in */Library/QuickLook* or *~/Library/QuickLook*.

Perhaps you will need to restart the *QuickLook* by running this command in the Terminal :

	qlmanage -r

For the others, open **qlImageSize.xcodeproj**. If you hit the run button, it will build the plugin, place it in *~/Library/QuickLook* and restart the *QuickLook* server automatically.

In the file **GenerateThumbnailForURL.m** you have the option to display the image type extension on the icons in the Finder. The extension is based on the Uniform Type Identifier (UTI) of the file.


### License ###

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE.txt**.

Blog : [Cocoa in the Shell](http://www.cocoaintheshell.com "Cocoa in the Shell")

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf)

------

### About Mavericks (OS X 10.9) ###

I am aware that qlImageSize does not fully work on Mavericks. By fully I mean it works for certain types like *tga*,*bmp*,*psd*,*tif* but not for the common ones *jpg*,*png*,*gif*.

it is a known bug in the OS and I can't do anything about it, but I encourage you to fill a bug to Apple (http://bugreport.apple.com)

For more informations, see https://github.com/Nyx0uf/qlImageSize/issues/4
