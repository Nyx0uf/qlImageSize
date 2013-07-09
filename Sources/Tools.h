//
//  Tools.h
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <CoreGraphics/CGImage.h>
#import <CoreGraphics/CGGeometry.h>


CF_RETURNS_RETAINED CFDictionaryRef createQLPreviewPropertiesForFile(CFURLRef url, CFTypeRef src, CFStringRef name, CGSize* imgSize, CGImageRef* img);
