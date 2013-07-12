//
//  Tools.m
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "Tools.h"
#import <sys/stat.h>
#import <sys/types.h>
#import <QuickLook/QLGenerator.h> // For kQLPreviewPropertyDisplayNameKey


CF_RETURNS_RETAINED CFDictionaryRef properties_for_file(CFTypeRef src, CFURLRef url)
{
	// Create the image source
	CGImageSourceRef imgSrc = (CFGetTypeID(src) == CFDataGetTypeID()) ? CGImageSourceCreateWithData(src, NULL) : CGImageSourceCreateWithURL(src, NULL);
	if (NULL == imgSrc)
		return NULL;
	
	// Copy images properties
	CFDictionaryRef imgProperties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
	if (NULL == imgProperties)
	{
		CFRelease(imgSrc);
		return NULL;
	}
	
	// Get image width
	CFNumberRef pWidth = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelWidth);
	//int width = 0;
	//CFNumberGetValue(pWidth, kCFNumberIntType, &width);
	// Get image height
	CFNumberRef pHeight = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelHeight);
	//int height = 0;
	//CFNumberGetValue(pHeight, kCFNumberIntType, &height);
	CFRelease(imgProperties);

	//CGRect imgFrame = (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height};
	//const bool b = CGRectContainsRect(screenFrame, imgFrame);

	CGImageRef imgRef = CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL);
	/*if (b)
	{
		imgRef = CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL);
	}
	else
	{
		CFTypeRef keys[2] = {kCGImageSourceCreateThumbnailFromImageIfAbsent, kCGImageSourceThumbnailMaxPixelSize};
		CFTypeRef values[2] = {kCFBooleanTrue, (__bridge CFNumberRef)(@(MAX(screenFrame.size.width, screenFrame.size.height)))};
		CFDictionaryRef opts = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		imgRef = CGImageSourceCreateThumbnailAtIndex(imgSrc, 0, opts);
		CFRelease(opts);
	}*/
	
	CFRelease(imgSrc);
	
	// Get the filesize, because it's not always present in the image properties dictionary :/
	UInt8 buf[4096] = {0x00};
	CFURLGetFileSystemRepresentation(url, true, buf, 4095);
	struct stat st;
	stat((const char*)buf, &st);

	// Create the properties dic
	const CFIndex MAXVALS = 4;
	CFTypeRef keys[MAXVALS] = {@"nyx.width", @"nyx.height", @"nyx.size", @"nyx.repr"};
	CFTypeRef values[MAXVALS] = {pWidth, pHeight, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &(st.st_size)), imgRef};
	CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, MAXVALS, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(values[2]);
	CGImageRelease(imgRef);
	return properties;
}
