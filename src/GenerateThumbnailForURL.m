//
//  GenerateThumbnailForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "Tools.h"


/// Comment this line if you don't want the type displayed inside the icon
#define kNyxDisplayTypeInIcon


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);


OSStatus GenerateThumbnailForURL(__unused void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options, __unused CGSize maxSize)
{
	CFDictionaryRef properties = NULL;
#ifdef kNyxDisplayTypeInIcon
	// Get the UTI properties
	NSDictionary* utiDeclarations = (__bridge_transfer NSDictionary*)UTTypeCopyDeclaration(contentTypeUTI);

	// Get the extensions corresponding to the image UTI, for some UTI there can be more than 1 extension (ex image.jpeg = jpeg, jpg...)
	id extensions = utiDeclarations[(__bridge NSString*)kUTTypeTagSpecificationKey][(__bridge NSString*)kUTTagClassFilenameExtension];
	NSString* extension = ([extensions isKindOfClass:[NSArray class]]) ? extensions[0] : extensions;

	// Create the properties dic
	CFTypeRef keys[1] = {kQLThumbnailPropertyExtensionKey};
	CFTypeRef values[1] = {(__bridge CFStringRef)extension};
	properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
#endif

	// Check by extension because it's highly unprobable that an UTI for these formats is declared
	// the simplest way to declare one is creating a dummy automator app and adding imported/exported UTI conforming to public.image
	NSString* urlExtension = [[(__bridge NSURL*)url pathExtension] lowercaseString];
	if ([urlExtension isEqualToString:@"webp"] || [urlExtension isEqualToString:@"pgm"] || [urlExtension isEqualToString:@"ppm"] || [urlExtension isEqualToString:@"pbm"] || [urlExtension isEqualToString:@"bpg"])
	{
		if (!QLThumbnailRequestIsCancelled(thumbnail))
		{
			// 1. decode the image
			__unused size_t width = 0, height = 0, fileSize = 0;
			CGImageRef imgRef = NULL;
			if ([urlExtension isEqualToString:@"webp"])
				imgRef = decode_webp(url, &width, &height, &fileSize);
			else if ([urlExtension isEqualToString:@"bpg"])
				imgRef = decode_bpg(url, &width, &height, &fileSize);
			else
				imgRef = decode_portable_pixmap(url, &width, &height, &fileSize);

			// 2. render it
			if (imgRef != NULL)
			{
				QLThumbnailRequestSetImage(thumbnail, imgRef, properties);
				CGImageRelease(imgRef);
			}
			else
				QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
		}
		else
			QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
	}
	else
		QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);

#ifdef kNyxDisplayTypeInIcon
	if (properties != NULL)
		CFRelease(properties);
#endif

	return kQLReturnNoError;
}

void CancelThumbnailGeneration(__unused void* thisInterface, __unused QLThumbnailRequestRef thumbnail)
{
}
