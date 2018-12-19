//
//  GenerateThumbnailForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//


#import <QuickLook/QuickLook.h>
#import "tools.h"

#ifdef NYX_QL_SUPPORT_BPG_DECODE
#import "bpg_decode.h"
#endif

#ifdef NYX_QL_SUPPORT_WEBP_DECODE
#import "webp_decode.h"
#endif

#ifdef NYX_QL_SUPPORT_NETPBM_DECODE
#import "netpbm_decode.h"
#endif


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);
void HandleFileForThumbnail(CFURLRef url, CGImageRef (*decode_fn_ptr)(CFStringRef, image_infos*), QLThumbnailRequestRef thumbnail);


OSStatus GenerateThumbnailForURL(__unused void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, __unused CFStringRef contentTypeUTI, __unused CFDictionaryRef options, __unused CGSize maxSize)
{
	@autoreleasepool
	{
		// Check by extension because it's highly unprobable that an UTI for these formats is declared
		// the simplest way to declare one is creating a dummy automator app and adding imported/exported UTI conforming to public.image
		NSString* extension = [[(__bridge NSURL*)url pathExtension] lowercaseString];
		CFDictionaryRef properties = NULL;

#ifdef NYX_QL_SUPPORT_BPG_DECODE
		if ([extension isEqualToString:@"bpg"])
		{
			HandleFileForThumbnail(url, &decode_bpg_at_path, thumbnail);
			return kQLReturnNoError;
		}
#endif
#ifdef NYX_QL_SUPPORT_WEBP_DECODE
		if ([extension isEqualToString:@"webp"])
		{
			HandleFileForThumbnail(url, &decode_webp_at_path, thumbnail);
			return kQLReturnNoError;
		}
#endif
#ifdef NYX_QL_SUPPORT_NETPBM_DECODE
		if ([extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"pbm"])
		{
			HandleFileForThumbnail(url, &decode_netpbm_at_path, thumbnail);
			return kQLReturnNoError;
		}
#endif
		QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
	}
	return kQLReturnNoError;
}

void HandleFileForThumbnail(CFURLRef url, CGImageRef (*decode_fn_ptr)(CFStringRef, image_infos*), QLThumbnailRequestRef thumbnail)
{
	CFDictionaryRef properties = NULL;
	if (!QLThumbnailRequestIsCancelled(thumbnail))
	{
		// 1. decode the image
		CFStringRef filepath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		CGImageRef img_ref = decode_fn_ptr(filepath, NULL);
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

void CancelThumbnailGeneration(__unused void* thisInterface, __unused QLThumbnailRequestRef thumbnail)
{
}
