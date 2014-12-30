//
//  GetMetadataForFile.m
//  qlImageSize
//
//  Created by @Nyx0uf on 20/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "bpg_decode.h"
#import "webp_decode.h"
#import "netpbm_decode.h"


Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);


Boolean GetMetadataForFile(__unused void* thisInterface, CFMutableDictionaryRef attributes, __unused CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
	@autoreleasepool
	{
		NSString* extension = [[(__bridge NSString*)pathToFile pathExtension] lowercaseString];
		if ([extension isEqualToString:@"webp"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pbm"] || [extension isEqualToString:@"bpg"])
		{
			image_infos infos;
			memset(&infos, 0, sizeof(image_infos));
			bool ret = FALSE;

			if ([extension isEqualToString:@"webp"])
			{
				/* WebP */
				ret = get_webp_informations_for_filepath(pathToFile, &infos);
			}
			else if ([extension isEqualToString:@"bpg"])
			{
				/* bpg */
				ret = get_bpg_informations_for_filepath(pathToFile, &infos);
			}
			else
			{
				/* Portable Pixmap */
				ret = get_netpbm_informations_for_filepath(pathToFile, &infos);
			}

			if (!ret)
				return FALSE;

			NSMutableDictionary* attrs = (__bridge NSMutableDictionary*)attributes;
			attrs[(NSString*)kMDItemPixelWidth] = @(infos.width);
			attrs[(NSString*)kMDItemPixelHeight] = @(infos.height);
			attrs[(NSString*)kMDItemPixelCount] = @(infos.height * infos.width);
			attrs[(NSString*)kMDItemHasAlphaChannel] = (!infos.has_alpha) ? @NO : @YES;
			attrs[(NSString*)kMDItemBitsPerSample] = @(infos.bit_depth);
			attrs[(NSString*)kMDItemColorSpace] = @(colorspace_string(infos.colorspace));
		}
	}

	return TRUE;
}
