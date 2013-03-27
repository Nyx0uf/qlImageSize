# qlImageSize #

This is a *QuickLook* plugin for Mac OS X *10.7* / *10.8* to display the dimensions of an image and its file size in the title bar.

Since *10.8* iPhone's PNG are correctly displayed in the Finder, but before they were not, so in *10.7* this plugin also correctly display them.

for more informations see my blog post about it : <http://www.cocoaintheshell.com/2012/02/quicklook-images-dimensions/>


### Build & Install ###

For those who don't want to build from the sources, you can grab the plugin here : <http://repo.whine.fr/qlImageSize.qlgenerator.zip>

Unzip it, and place it in */Library/QuickLook* or *~/Library/QuickLook*.

Perhaps you will need to restart the *QuickLook* server using this command :

	qlmanage -r

For the others, open **qlImageSize.xcodeproj**. If you hit the run button, it will build the plugin, place it in *~/Library/QuickLook* and restart the *QuickLook* server automatically.

In the file **GenerateThumbnailForURL.m** you have the option to display the image type extension on the icons in the Finder. The extension is based on the Uniform Type Identifier (UTI) of the file.

Also, ***qlImageSize*** is **ARC** enabled.


### License ###

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE.txt**.

Blog : <http://www.cocoaintheshell.com/>

Twitter : @Nyx0uf
