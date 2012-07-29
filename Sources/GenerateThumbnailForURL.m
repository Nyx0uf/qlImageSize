//
//  GenerateThumbnailForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Benjamin Godard. All rights reserved.
//  www.cococabyss.com
//


#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "Tools.h"
#import "NYXPNGTools.h"


/// Comment this line if you don't want the type displayed inside the icon
#define kNyxDisplayTypeInIcon


OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */
OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	@autoreleasepool
	{
		CFDictionaryRef properties = NULL;
#ifdef kNyxDisplayTypeInIcon
		/// Get the UTI properties
		NSDictionary* utiDeclarations = (__bridge_transfer NSDictionary*)UTTypeCopyDeclaration(contentTypeUTI);

		/// Get the extensions corresponding to the image UTI, for some UTI there can be more than 1 extension (ex image.jpeg = jpeg, jpg...)
		id extensions = utiDeclarations[(__bridge NSString*)kUTTypeTagSpecificationKey][(__bridge NSString*)kUTTagClassFilenameExtension];
		NSString* extension = ([extensions isKindOfClass:[NSArray class]]) ? extensions[0] : extensions;

		/// Create the properties dic
		CFTypeRef keys[1] = {kQLThumbnailPropertyExtensionKey};
		CFTypeRef values[1] = {(__bridge CFStringRef)extension};
		properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
#endif
		/// Check if the image is a PNG
		if (CFStringCompare(contentTypeUTI, kUTTypePNG, kCFCompareCaseInsensitive) == kCFCompareEqualTo)
		{
			const char* path = [[(__bridge NSURL*)url path] cStringUsingEncoding:NSUTF8StringEncoding];
			int error = 0;
			if (npt_is_apple_crushed_png(path, &error))
			{
				/// Uncrush the PNG
				unsigned int size = 0;
				UInt8* pngData = npt_create_uncrushed_from_file(path, &size, &error);
				if (!pngData)
				{
					NSLog(@"[+] qlImageSize: Failed to create uncrushed png from '%@' : %s", url, npt_error_message(error));
				}
				else
				{
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
		}
		else
			QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
		
#ifdef kNyxDisplayTypeInIcon
		SAFE_RELEASE_CF(properties);
#endif

		return kQLReturnNoError;
	}
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
	// Implement only if supported
}
