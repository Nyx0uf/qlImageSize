//
//  GeneratePreviewForURL.c
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

// To enable logging --> defaults write -g QLEnableLogging NO
OSStatus GeneratePreviewForURL(void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);
void HandleFileForPreview(CFURLRef url, CGImageRef (*decode_fn_ptr)(CFStringRef, image_infos*), QLPreviewRequestRef preview, CFStringRef contentTypeUTI);
CF_RETURNS_RETAINED static CFDictionaryRef _create_properties(CFURLRef url, const size_t size, const size_t width, const size_t height, const size_t dpi, const bool b);


OSStatus GeneratePreviewForURL(__unused void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options)
{
	@autoreleasepool
	{
		// Non-standard images (not supported by the OS by default)
		// Check by extension because it's highly unprobable that an UTI for these formats is declared
		NSString* extension = [[(__bridge NSURL*)url pathExtension] lowercaseString];

#ifdef NYX_QL_SUPPORT_BPG_DECODE
		if ([extension isEqualToString:@"bpg"])
		{
			HandleFileForPreview(url, &decode_bpg_at_path, preview, contentTypeUTI);
			return kQLReturnNoError;
		}
#endif
#ifdef NYX_QL_SUPPORT_WEBP_DECODE
		if ([extension isEqualToString:@"webp"])
		{
			HandleFileForPreview(url, &decode_webp_at_path, preview, contentTypeUTI);
			return kQLReturnNoError;
		}
#endif
#ifdef NYX_QL_SUPPORT_NETPBM_DECODE
		if ([extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"pbm"])
		{
			HandleFileForPreview(url, &decode_netpbm_at_path, preview, contentTypeUTI);
			return kQLReturnNoError;
		}
#endif
		// Standard images (supported by the OS by default)
		size_t width = 0, height = 0, dpi = 0, file_size = 0;
		properties_for_file(url, &width, &height, &dpi, &file_size);

		// Request preview with updated titlebar
		CFDictionaryRef properties = _create_properties(url, file_size, width, height, dpi, false);
		QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);

		SAFE_CFRelease(properties);
	}
	return kQLReturnNoError;
}

void HandleFileForPreview(CFURLRef url, CGImageRef (*decode_fn_ptr)(CFStringRef, image_infos*), QLPreviewRequestRef preview, CFStringRef contentTypeUTI)
{
	// 1. decode the image
	if (!QLPreviewRequestIsCancelled(preview))
	{
		image_infos infos;
		memset(&infos, 0, sizeof(image_infos));
		CFStringRef filepath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		CGImageRef img_ref = decode_fn_ptr(filepath, &infos);
		SAFE_CFRelease(filepath);

		// 2. render it
		CFDictionaryRef properties = _create_properties(url, infos.filesize, infos.width, infos.height, infos.dpi, true);
		if (img_ref != NULL)
		{
			// Have to draw the image ourselves
			CGContextRef ctx = QLPreviewRequestCreateContext(preview, (CGSize){.width = infos.width, .height = infos.height}, YES, properties);
			CGContextDrawImage(ctx, (CGRect){.origin = CGPointZero, .size.width = infos.width, .size.height = infos.height}, img_ref);
			QLPreviewRequestFlushContext(preview, ctx);
			CGContextRelease(ctx);
			CGImageRelease(img_ref);
		}
		else
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);
		SAFE_CFRelease(properties);
	}
}

void CancelPreviewGeneration(__unused void* thisInterface, __unused QLPreviewRequestRef preview)
{
}

CF_RETURNS_RETAINED static CFDictionaryRef _create_properties(CFURLRef url, const size_t size, const size_t width, const size_t height, const size_t dpi, const bool b)
{
	// Format file size
	NSString* fmt = nil;
	if (size > 1048576) // More than 1Mb
		fmt = [[NSString alloc] initWithFormat:@"%.1fMb", (float)((float)size / 1048576.0f)];
	else if ((size < 1048576) && (size > 1024)) // 1Kb - 1Mb
		fmt = [[NSString alloc] initWithFormat:@"%.2fKb", (float)((float)size / 1024.0f)];
	else // Less than 1Kb
		fmt = [[NSString alloc] initWithFormat:@"%zub", size];

	// Get filename
	CFStringRef filename = CFURLCopyLastPathComponent(url);

	// Create props
	CFDictionaryRef properties = NULL;
	if (b)
	{
		CFTypeRef keys[3] = {kQLPreviewPropertyDisplayNameKey, kQLPreviewPropertyWidthKey, kQLPreviewPropertyHeightKey};
		// WIDTHxHEIGHT • 25.01Kb • filename
		CFStringRef title = dpi > 0 ? CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d (%ddpi) • %@ • %@"), (int)width, (int)height, (int)dpi, fmt, filename) : CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d • %@ • %@"), (int)width, (int)height, fmt, filename);
		CFTypeRef values[3] = {title, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &width), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &height)};
		properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		SAFE_CFRelease(values[0]);
		SAFE_CFRelease(values[1]);
		SAFE_CFRelease(values[2]);
	}
	else
	{
		CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
		// WIDTHxHEIGHT • 25.01Kb • filename
		CFStringRef title = dpi > 0 ? CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d (%ddpi) • %@ • %@"), (int)width, (int)height, (int)dpi, fmt, filename) : CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d • %@ • %@"), (int)width, (int)height, fmt, filename);
		CFTypeRef values[1] = {title};
		properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		SAFE_CFRelease(values[0]);
	}

	SAFE_CFRelease(filename);

	return properties;
}
