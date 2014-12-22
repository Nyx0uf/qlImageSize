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
	NSString* extension = [[(__bridge NSURL*)url pathExtension] lowercaseString];
	if ([extension isEqualToString:@"webp"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pbm"] || [extension isEqualToString:@"bpg"])
	{
		// Non-standard images (not supported by the OS by default)
		// Check by extension because it's highly unprobable that an UTI for these formats is declared

		// 1. decode the image
		if (!QLPreviewRequestIsCancelled(preview))
		{
			size_t width = 0, height = 0, file_size = 0;
			CGImageRef img_ref = NULL;
			if ([extension isEqualToString:@"webp"])
				img_ref = decode_webp(url, &width, &height, &file_size);
			else if ([extension isEqualToString:@"bpg"])
				img_ref = decode_bpg(url, &width, &height, &file_size);
			else
				img_ref = decode_portable_pixmap(url, &width, &height, &file_size);

			// 2. render it
			CFDictionaryRef properties = _create_properties(url, file_size, width, height, true);
			if (img_ref != NULL)
			{
				// Have to draw the image ourselves
				CGContextRef ctx = QLPreviewRequestCreateContext(preview, (CGSize){.width = width, .height = height}, YES, properties);
				CGContextDrawImage(ctx, (CGRect){.origin = CGPointZero, .size.width = width, .size.height = height}, img_ref);
				QLPreviewRequestFlushContext(preview, ctx);
				CGContextRelease(ctx);
				CGImageRelease(img_ref);
			}
			else
				QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);
			if (properties != NULL)
				CFRelease(properties);
		}
	}
	else
	{
		// Standard images (supported by the OS by default)

		size_t width = 0, height = 0, file_size = 0;
		properties_for_file(url, &width, &height, &file_size);

		// Request preview with updated titlebar
		CFDictionaryRef properties = _create_properties(url, file_size, width, height, false);
		QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);

		if (properties != NULL)
			CFRelease(properties);
	}

	return kQLReturnNoError;
}

void CancelPreviewGeneration(__unused void* thisInterface, __unused QLPreviewRequestRef preview)
{
}

CF_RETURNS_RETAINED static CFDictionaryRef _create_properties(CFURLRef url, const size_t size, const size_t width, const size_t height, const bool b)
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
		CFTypeRef values[3] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d • %@ • %@"), (int)width, (int)height, fmt, filename), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &width), CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &height)};
		properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(values[0]);
		CFRelease(values[1]);
		CFRelease(values[2]);
	}
	else
	{
		CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
		// WIDTHxHEIGHT • 25.01Kb • filename
		CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d • %@ • %@"), (int)width, (int)height, fmt, filename)};
		properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(values[0]);
	}

	CFRelease(filename);

	return properties;
}
