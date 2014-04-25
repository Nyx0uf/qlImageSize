# qlImageSize

This is a **QuickLook** plugin for Mac OS X *10.7* / *10.8* to display the dimensions of an image and its file size in the title bar.

Since *10.8* iPhone's PNG are correctly displayed in the Finder, but before they were not, so in *10.7* this plugin also correctly display them.

for more informations see my [blog post about it](http://www.cocoaintheshell.com/2012/02/quicklook-images-dimensions/ "Images dimensions in QuickLook").


### Installation

Download the plugin here :

[- Lion (10.7)](http://repo.whine.fr/qlImageSize.qlgenerator-10.7.zip "qlImageSize for 10.7")

[- Moutain Lion / Mavericks (10.8 / 10.9)](http://repo.whine.fr/qlImageSize.qlgenerator-10.8.zip "qlImageSize for 10.8+")

Unzip it, and place it in */Library/QuickLook* or *~/Library/QuickLook*.

You will need to restart the *QuickLook* daemon by running these commands in the Terminal :

	qlmanage -r
	qlmanage -r cache


### License

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE**.

Blog : [Cocoa in the Shell](http://www.cocoaintheshell.com "Cocoa in the Shell")

Twitter : [@Nyx0uf](https://twitter.com/Nyx0uf "Nyx0uf on Twitter")

------

### About Mavericks (OS X 10.9) ###

I am aware that qlImageSize does not fully work on Mavericks. By fully I mean it works for certain types like *tga*,*bmp*,*psd*,*tif* but not for the common ones *jpg*,*png*,*gif*.

it is a known bug in the OS and I can't do anything about it, but I encourage you to fill a bug to Apple (http://bugreport.apple.com)

For more informations, see https://github.com/Nyx0uf/qlImageSize/issues/4
