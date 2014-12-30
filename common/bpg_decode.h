//
//  bpg_decode.h
//  qlImageSize
//
//  Created by @Nyx0uf on 30/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "tools.h"


CF_RETURNS_RETAINED CGImageRef decode_bpg_at_path(CFStringRef filepath, image_infos* infos);

bool get_bpg_informations_for_filepath(CFStringRef filepath, image_infos* infos);
