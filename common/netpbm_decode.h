//
//  netpbm_decode.h
//  qlImageSize
//
//  Created by @Nyx0uf on 30/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//


#import "tools.h"


#ifdef NYX_QL_SUPPORT_NETPBM_DECODE
CF_RETURNS_RETAINED CGImageRef decode_netpbm_at_path(CFStringRef filepath,  image_infos* infos);
#endif

#ifdef NYX_MD_SUPPORT_NETPBM_DECODE
bool get_netpbm_informations_for_filepath(CFStringRef filepath, image_infos* infos);
#endif
