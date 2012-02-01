//
//  GeneratePreviewForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright 2012 Benjamin Godard. All rights reserved.
//  www.cococabyss.com
//


#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
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

	CFStringRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
	CFStringRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%dx%d"), width, height)};
	CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);

	CFRelease(values[0]);
	CFRelease(properties);

	return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
	// Implement only if supported
}
