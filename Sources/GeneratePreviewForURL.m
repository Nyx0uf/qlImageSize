//
//  GeneratePreviewForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Tools.h"


OSStatus GeneratePreviewForURL(void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);


OSStatus GeneratePreviewForURL(__unused void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options)
{
	@autoreleasepool
	{
		CFDictionaryRef properties = properties_for_file(url, url);
		if (NULL == properties)
		{
			// Some kind of error, fallback & abort
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
			return kQLReturnNoError;
		}

		// Create the string containing dimensions
		const CGSize imgSize = (CGSize){.width = [(__bridge NSNumber*)CFDictionaryGetValue(properties, NYX_KEY_IMGWIDTH) integerValue], .height = [(__bridge NSNumber*)CFDictionaryGetValue(properties, NYX_KEY_IMGHEIGHT) integerValue]};

		// Create a local properties dic to update titlebar
		CFNumberRef n = CFDictionaryGetValue(properties, NYX_KEY_IMGSIZE);
		int64_t size = 0;
		CFNumberGetValue(n, kCFNumberSInt64Type, &size);
		NSString* fmtSize = nil;
		if (size > 1048576) // More than 1Mb
			fmtSize = [[NSString alloc] initWithFormat:@"%.1fMb", (float)((float)size / 1048576.0f)];
		else if ((size < 1048576) && (size > 1024)) // 1Kb - 1Mb
			fmtSize = [[NSString alloc] initWithFormat:@"%.2fKb", (float)((float)size / 1024.0f)];
		else // Less than 1Kb
			fmtSize = [[NSString alloc] initWithFormat:@"%lldb", size];
		CFStringRef filename = CFURLCopyLastPathComponent(url);
		CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
		// WIDTHxHEIGHT • 25.01Kb • filename
		CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d • %@ • %@"), (int)imgSize.width, (int)imgSize.height, fmtSize, filename)};
		CFDictionaryRef props = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(values[0]);
		CFRelease(filename);

		// Request preview with updated titlebar
		QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, props);

		if (props != NULL)
			CFRelease(props);

		CFRelease(properties);

		return kQLReturnNoError;
	}
}

void CancelPreviewGeneration(__unused void* thisInterface, __unused QLPreviewRequestRef preview)
{
}
