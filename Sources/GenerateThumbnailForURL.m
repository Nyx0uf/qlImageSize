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
#import <Foundation/NSURL.h>


#if (__MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8)
#import "NYXPNGTools.h"
#endif /* __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8 */


/// Comment this line if you don't want the type displayed inside the icon
#define kNyxDisplayTypeInIcon


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */
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
		// Check if the image is a PNG
		if (CFStringCompare(contentTypeUTI, kUTTypePNG, kCFCompareCaseInsensitive) == kCFCompareEqualTo)
		{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8)
			const char* path = [[(__bridge NSURL*)url path] cStringUsingEncoding:NSUTF8StringEncoding];
			int error = 0;
			if (npt_is_apple_crushed_png(path, &error))
			{
				if (QLThumbnailRequestIsCancelled(thumbnail))
				{
#ifdef kNyxDisplayTypeInIcon
					if (properties != NULL)
						CFRelease(properties);
#endif /* kNyxDisplayTypeInIcon */
					return kQLReturnNoError;
				}
				// Uncrush the PNG
				unsigned int size = 0;
				UInt8* pngData = npt_create_uncrushed_from_file(path, &size, &error);
				if (!pngData)
				{
					NSLog(@"[+] qlImageSize: Failed to create uncrushed png from '%@' : %s", url, npt_error_message(error));
				}
				else
				{
					if (QLThumbnailRequestIsCancelled(thumbnail))
					{
#ifdef kNyxDisplayTypeInIcon
						if (properties != NULL)
							CFRelease(properties);
#endif /* kNyxDisplayTypeInIcon */
						free(pngData);
						return kQLReturnNoError;
					}
					CFDataRef uncrushed = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pngData, size, kCFAllocatorDefault);
					if (uncrushed)
					{
						QLThumbnailRequestSetImageWithData(thumbnail, uncrushed, properties);
						CFRelease(uncrushed); // Will also free pngData
					}
					else
					{
						free(pngData);
						NSLog(@"[+] qlImageSize: Failed to create uncrushed png from '%@'", url);
					}
				}
			}
			else
				QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
#else
			QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
#endif /* __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8 */
		}
		else
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
