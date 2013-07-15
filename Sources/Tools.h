//
//  Tools.h
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#define NYX_KEY_IMGWIDTH @"nyx.width"
#define NYX_KEY_IMGHEIGHT @"nyx.height"
#define NYX_KEY_IMGSIZE @"nyx.size"
#define NYX_KEY_IMGREPR @"nyx.repr"


CF_RETURNS_RETAINED CFDictionaryRef properties_for_file(CFTypeRef src, CFURLRef url);
