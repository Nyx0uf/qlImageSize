//
//  Tools.m
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Benjamin Godard. All rights reserved.
//  www.cococabyss.com
//


#import "Tools.h"
#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import <sys/types.h>
#import <QuickLook/QLGenerator.h>


CFDictionaryRef createQLPreviewPropertiesForFile(CFURLRef url, CFTypeRef src, CFStringRef name)
{
	/// Create the image source
	CGImageSourceRef imgSrc = NULL;
	if (CFGetTypeID(src) == CFDataGetTypeID())
		imgSrc = CGImageSourceCreateWithData(src, NULL);
	else
		imgSrc = CGImageSourceCreateWithURL(src, NULL);
	if (!imgSrc)
		return NULL;

	/// Copy images properties
	CFDictionaryRef imgProperties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
	CFRelease(imgSrc);
	if (!imgProperties)
		return NULL;

	/// Get image width
	CFNumberRef w = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelWidth);
	int width = 0;
	CFNumberGetValue(w, kCFNumberIntType, &width);
	/// Get image height
	CFNumberRef h = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelHeight);
	int height = 0;
	CFNumberGetValue(h, kCFNumberIntType, &height);
	CFRelease(imgProperties);

	/// Get the filesize, because it's not always present in the image properties dictionary :/
	struct stat st;
	stat([[(__bridge NSURL*)url path] cStringUsingEncoding:NSUTF8StringEncoding], &st);
	/// Create the display size format
	NSString* fmtSize = nil;
	if (st.st_size > 1048576) // More than 1Mb
		fmtSize = [[NSString alloc] initWithFormat:@"%.1fMb", (float)((float)st.st_size / 1048576.0f)];
	else if (st.st_size < 1048576 && st.st_size > 1024) // 1Kb - 1Mb
		fmtSize = [[NSString alloc] initWithFormat:@"%.2fKb", (float)((float)st.st_size / 1024.0f)];
	else // Less than 1Kb
		fmtSize = [[NSString alloc] initWithFormat:@"%lldb", st.st_size];

	/// Create the properties dic
	CFTypeRef keys[1] = {kQLPreviewPropertyDisplayNameKey};
	CFTypeRef values[1] = {CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%@ (%dx%d - %@)"), name, width, height, fmtSize)}; // bla.png (64x64 - 137b)
	CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	SAFE_RELEASE_CF(values[0]);
	return properties;
}
