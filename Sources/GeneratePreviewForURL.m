//
//  GeneratePreviewForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright 2012 Benjamin Godard. All rights reserved.
//  www.cococabyss.com
//


#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import <sys/types.h>


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */
OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	@autoreleasepool
	{
		CGImageSourceRef imgSrc = CGImageSourceCreateWithURL(url, NULL);
		if (!imgSrc)
		{
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
			return -1;
		}

		/// Copy images properties
		CFDictionaryRef imgProperties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
		CFRelease(imgSrc);
		if (!imgProperties)
		{
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, NULL);
			return -1;
		}
		CFNumberRef w = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelWidth);
		int width = 0;
		CFNumberGetValue(w, kCFNumberIntType, &width);
		CFNumberRef h = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelHeight);
		int height = 0;
		CFNumberGetValue(h, kCFNumberIntType, &height);
		CFRelease(imgProperties);
		/// Could be nice to get DPI infos with kCGImagePropertyDPIHeight & kCGImagePropertyDPIWidth
		
		NSString* filePath = [(__bridge NSURL*)url path];
		struct stat st;
		stat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st);
		NSString* filename = [filePath lastPathComponent];
		NSString* fmtSize = nil;
		if (st.st_size > 1048576) // More than 1Mb
			fmtSize = [[NSString alloc] initWithFormat:@"%.2fMb", (float)((float)st.st_size / 1048576.0f)];
		else if (st.st_size < 1048576 && st.st_size > 1024) // 1Kb - 1Mb
			fmtSize = [[NSString alloc] initWithFormat:@"%.2fKb", (float)((float)st.st_size / 1024.0f)];
		else // Less than 1Kb
			fmtSize = [[NSString alloc] initWithFormat:@"%ldb", st.st_size];
		
		CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
		CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%@ (%dx%d - %@)"), filename, width, height, fmtSize)};
		CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);
		
		CFRelease(values[0]);
		CFRelease(properties);
		
		return kQLReturnNoError;
	}
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
	// Implement only if supported
}
