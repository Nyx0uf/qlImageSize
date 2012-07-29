# qlImageSize #

This is a *QuickLook* plugin for Mac OS X Lion (**10.7**) to display the dimensions of an image and its size in the title bar. It also displays iPhone crushed PNG in the finder on the fly without creation of any temporary files.

for more informations see my blog post about it : <http://www.cocoaintheshell.com/2012/02/quicklook-images-dimensions/>


### Build & Install ###

For those who don't want to build from the sources, you can grab the plugin here : <https://github.com/downloads/Nyx0uf/qlImageSize/qlImageSize.qlgenerator.zip>

Unzip it, and place it in */Library/QuickLook* or *~/Library/QuickLook*.

Perhaps you will need to restart the QuickLook server using this command :

	qlmanage -r

For the others, open **qlImageSize.xcodeproj**. If you hit the run button, it will build the plugin, place it in *~/Library/QuickLook* and restart the QuickLook server automatically.

In the file **GenerateThumbnailForURL.m** you have the option to display the image type extension on the icons in the Finder. The extension is based on the Uniform Type Identifier (UTI) of the file.

Also, ***qlImageSize*** is **ARC** enabled.


### License ###

***qlImageSize*** is released under the *Simplified BSD license*, see **LICENSE.txt**.

Blog : <http://www.cocoaintheshell.com/>

Twitter : @Nyx0uf
