//
//  Tools.h
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//

#import <Foundation/Foundation.h>


void properties_for_file(CFURLRef url, size_t* width, size_t* height, size_t* fileSize);

CF_RETURNS_RETAINED CGImageRef decode_webp(CFURLRef url, size_t* width, size_t* height, size_t* fileSize);

CF_RETURNS_RETAINED CGImageRef decode_bpg(CFURLRef url, size_t* width, size_t* height, size_t* fileSize);

CF_RETURNS_RETAINED CGImageRef decode_portable_pixmap(CFURLRef url, size_t* width, size_t* height, size_t* fileSize);
