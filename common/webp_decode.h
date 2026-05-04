//
//  webp_decode.h
//  qlImageSize
//
//  Created by @Nyx0uf on 30/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//

@import CoreGraphics;

#import "tools.h"

#ifdef NYX_QL_SUPPORT_WEBP_DECODE
CF_RETURNS_RETAINED CGImageRef decode_webp_at_path(CFStringRef filepath,  image_infos* infos);
#endif

#ifdef NYX_MD_SUPPORT_WEBP_DECODE
bool get_webp_informations_for_filepath(CFStringRef filepath, image_infos* infos);
#endif
