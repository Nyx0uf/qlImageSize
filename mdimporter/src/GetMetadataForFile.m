//
//  GetMetadataForFile.m
//  qlImageSize
//
//  Created by @Nyx0uf on 20/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//


#import "tools.h"

#ifdef NYX_MD_SUPPORT_BPG_DECODE
#import "bpg_decode.h"
#endif

#ifdef NYX_MD_SUPPORT_WEBP_DECODE
#import "webp_decode.h"
#endif

#ifdef NYX_MD_SUPPORT_NETPBM_DECODE
#import "netpbm_decode.h"
#endif


Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);
bool GetImageInfos(CFStringRef pathToFile, NSMutableDictionary* attrs, bool (*infos_fn_ptr)(CFStringRef, image_infos*));


Boolean GetMetadataForFile(__unused void* thisInterface, CFMutableDictionaryRef attributes, __unused CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
	@autoreleasepool
	{
		NSString* extension = [[(__bridge NSString*)pathToFile pathExtension] lowercaseString];

#ifdef NYX_MD_SUPPORT_BPG_DECODE
		if ([extension isEqualToString:@"bpg"])
		{
			return GetImageInfos(pathToFile, (__bridge NSMutableDictionary*)attributes, &get_bpg_informations_for_filepath);
		}
#endif
#ifdef NYX_MD_SUPPORT_WEBP_DECODE
		if ([extension isEqualToString:@"webp"])
		{
			return GetImageInfos(pathToFile, (__bridge NSMutableDictionary*)attributes, &get_webp_informations_for_filepath);
		}
#endif
#ifdef NYX_MD_SUPPORT_NETPBM_DECODE
		if ([extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"pbm"])
		{
			return GetImageInfos(pathToFile, (__bridge NSMutableDictionary*)attributes, &get_netpbm_informations_for_filepath);
		}
#endif
	}

	return TRUE;
}

bool GetImageInfos(CFStringRef pathToFile, NSMutableDictionary* attrs, bool (*infos_fn_ptr)(CFStringRef, image_infos*))
{
	image_infos infos;
	memset(&infos, 0, sizeof(image_infos));
	bool ret = infos_fn_ptr(pathToFile, &infos);

	if (!ret)
		return FALSE;

	attrs[(NSString*)kMDItemPixelWidth] = @(infos.width);
	attrs[(NSString*)kMDItemPixelHeight] = @(infos.height);
	attrs[(NSString*)kMDItemPixelCount] = @(infos.height * infos.width);
	attrs[(NSString*)kMDItemHasAlphaChannel] = (!infos.has_alpha) ? @NO : @YES;
	attrs[(NSString*)kMDItemBitsPerSample] = @(infos.bit_depth);
	attrs[(NSString*)kMDItemColorSpace] = @(colorspace_string(infos.colorspace));

	return TRUE;
}
