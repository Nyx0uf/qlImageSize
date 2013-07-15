//
//  GenerateThumbnailForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>


/// Comment this line if you don't want the type displayed inside the icon
#define kNyxDisplayTypeInIcon


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);


OSStatus GenerateThumbnailForURL(__unused void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options, __unused CGSize maxSize)
{
	@autoreleasepool
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
#endif /* kNyxDisplayTypeInIcon */

		QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
		
#ifdef kNyxDisplayTypeInIcon
		if (properties != NULL)
			CFRelease(properties);
#endif /* kNyxDisplayTypeInIcon */

		return kQLReturnNoError;
	}
}

void CancelThumbnailGeneration(__unused void* thisInterface, __unused QLThumbnailRequestRef thumbnail)
{
}
