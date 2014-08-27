//
//  GeneratePreviewForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "Tools.h"


OSStatus GeneratePreviewForURL(void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);
CF_RETURNS_RETAINED static CFDictionaryRef _create_properties(CFURLRef url, const size_t size, const size_t width, const size_t height, const bool b);


OSStatus GeneratePreviewForURL(__unused void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options)
{
	NSString* urlExtension = [[(__bridge NSURL*)url pathExtension] lowercaseString];
	if ([urlExtension isEqualToString:@"webp"] || [urlExtension isEqualToString:@"pgm"] || [urlExtension isEqualToString:@"ppm"] || [urlExtension isEqualToString:@"pbm"])
	{
		// Non-standard images (not supported by the OS by default)
		// Check by extension because it's highly unprobable that an UTI for pixmap is declared

		// 1. decode the image
		if (!QLPreviewRequestIsCancelled(preview))
		{
			size_t width = 0, height = 0, fileSize = 0;
			CGImageRef imgRef = NULL;
			if ([urlExtension isEqualToString:@"webp"])
				imgRef = decode_webp(url, &width, &height, &fileSize);
			else
				imgRef = decode_portable_pixmap(url, &width, &height, &fileSize);

			// 2. render it
			if (imgRef != NULL)
			{
				// Have to draw the image ourselves
				CFDictionaryRef props = _create_properties(url, fileSize, width, height, true);
				CGContextRef ctx = QLPreviewRequestCreateContext(preview, (CGSize){.width = width, .height = height}, YES, props);
				CGContextDrawImage(ctx, (CGRect){.origin = CGPointZero, .size.width = width, .size.height = height}, imgRef);
				QLPreviewRequestFlushContext(preview, ctx);
				CGContextRelease(ctx);
				if (props != NULL)
					CFRelease(props);
				CGImageRelease(imgRef);
			}
			else
				QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
		}
	}
	else
	{
		// Standard images (supported by the OS by default)

		size_t width = 0, height = 0, fileSize = 0;
		properties_for_file(url, &width, &height, &fileSize);

		// Request preview with updated titlebar
		CFDictionaryRef props = _create_properties(url, fileSize, width, height, false);
		QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, props);

		if (props != NULL)
			CFRelease(props);
	}

	return kQLReturnNoError;
}

void CancelPreviewGeneration(__unused void* thisInterface, __unused QLPreviewRequestRef preview)
{
}

CF_RETURNS_RETAINED static CFDictionaryRef _create_properties(CFURLRef url, const size_t size, const size_t width, const size_t height, const bool b)
{
	// Format file size
	NSString* fmtSize = nil;
	if (size > 1048576) // More than 1Mb
		fmtSize = [[NSString alloc] initWithFormat:@"%.1fMb", (float)((float)size / 1048576.0f)];
	else if ((size < 1048576) && (size > 1024)) // 1Kb - 1Mb
		fmtSize = [[NSString alloc] initWithFormat:@"%.2fKb", (float)((float)size / 1024.0f)];
	else // Less than 1Kb
		fmtSize = [[NSString alloc] initWithFormat:@"%zub", size];

	// Get filename
	CFStringRef filename = CFURLCopyLastPathComponent(url);

	// Create props
	CFDictionaryRef props = NULL;
	if (b)
	{
		CFTypeRef keys[3] = {kQLPreviewPropertyDisplayNameKey, kQLPreviewPropertyWidthKey, kQLPreviewPropertyHeightKey};
		// WIDTHxHEIGHT • 25.01Kb • filename
		CFTypeRef values[3] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d • %@ • %@"), (int)width, (int)height, fmtSize, filename), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &width), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &height)};
		props = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(values[0]);
		CFRelease(values[1]);
		CFRelease(values[2]);
	}
	else
	{
		CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
		// WIDTHxHEIGHT • 25.01Kb • filename
		CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d • %@ • %@"), (int)width, (int)height, fmtSize, filename)};
		props = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(values[0]);
	}

	CFRelease(filename);

	return props;
}
