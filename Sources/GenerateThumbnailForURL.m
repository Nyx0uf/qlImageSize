//
//  GenerateThumbnailForURL.c
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


#define kNyxDisplayTypeInIcon


OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	/// If we don't do this, images icon are generic

	CFDictionaryRef properties = NULL;
#ifdef kNyxDisplayTypeInIcon
	/// Get the UTI properties
	NSDictionary* utiDeclarations = (__bridge_transfer NSDictionary*)UTTypeCopyDeclaration(contentTypeUTI);
	/// Get the extensions corresponding to the image UTI, for some UTI there can be more than 1 extension (ex image.jpeg = jpeg, jpg...)
	id extensions = [[utiDeclarations objectForKey:(__bridge NSString*)kUTTypeTagSpecificationKey] objectForKey:(__bridge NSString*)kUTTagClassFilenameExtension];
	NSString* extension = ([extensions isKindOfClass:[NSArray class]]) ? [extensions objectAtIndex:0] : extensions;
	
	CFTypeRef keys[1] = {kQLThumbnailPropertyExtensionKey};
	CFTypeRef values[1] = {(__bridge CFStringRef)extension};
	properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
#endif
	QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);

#ifdef kNyxDisplayTypeInIcon
	SAFE_RELEASE_CF
	(properties);
#endif
	
	return kQLReturnNoError;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
	// Implement only if supported
}
