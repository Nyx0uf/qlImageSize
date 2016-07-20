//
//  GenerateThumbnailForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "bpg_decode.h"
#import "webp_decode.h"
#import "netpbm_decode.h"


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);


OSStatus GenerateThumbnailForURL(__unused void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, __unused CFStringRef contentTypeUTI, __unused CFDictionaryRef options, __unused CGSize maxSize)
{
	@autoreleasepool
	{
		// Check by extension because it's highly unprobable that an UTI for these formats is declared
		// the simplest way to declare one is creating a dummy automator app and adding imported/exported UTI conforming to public.image
		NSString* extension = [[(__bridge NSURL*)url pathExtension] lowercaseString];
		CFDictionaryRef properties = NULL;
		if ([extension isEqualToString:@"webp"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pbm"] || [extension isEqualToString:@"bpg"])
		{
			if (!QLThumbnailRequestIsCancelled(thumbnail))
			{
				// 1. decode the image
				CGImageRef img_ref = NULL;
				CFStringRef filepath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
				if ([extension isEqualToString:@"webp"])
					img_ref = decode_webp_at_path(filepath, NULL);
				else if ([extension isEqualToString:@"bpg"])
					img_ref = decode_bpg_at_path(filepath, NULL);
				else
					img_ref = decode_netpbm_at_path(filepath, NULL);
				SAFE_CFRelease(filepath);

				// 2. render it
				if (img_ref != NULL)
				{
					QLThumbnailRequestSetImage(thumbnail, img_ref, properties);
					CGImageRelease(img_ref);
				}
				else
					QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
			}
			else
				QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
		}
		else
			QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);

		//SAFE_CFRelease(properties);
	}
	return kQLReturnNoError;
}

void CancelThumbnailGeneration(__unused void* thisInterface, __unused QLThumbnailRequestRef thumbnail)
{
}
