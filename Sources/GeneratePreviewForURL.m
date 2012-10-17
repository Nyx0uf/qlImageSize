//
//  GeneratePreviewForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "Tools.h"

#if __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
#import "NYXPNGTools.h"
#endif /* __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8 */


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
#if __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
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
					NSLog(@"[-] qlImageSize: Failed to create uncrushed png from '%@' : %s", url, npt_error_message(error));
				}
				else
				{
					CFDataRef uncrushed = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pngData, size, kCFAllocatorDefault);
					if (uncrushed)
					{
						/// Create the properties dic
						CFStringRef filename = CFURLCopyLastPathComponent(url);
						CFDictionaryRef properties = createQLPreviewPropertiesForFile(url, uncrushed, filename);					
						QLPreviewRequestSetDataRepresentation(preview, uncrushed, contentTypeUTI, properties);
						CFRelease(properties);
						CFRelease(filename);
						CFRelease(uncrushed); // Will also free pngData
					}
					else
					{
						free(pngData);
						NSLog(@"[-] qlImageSize: Failed to create uncrushed png from '%@'", url);
					}
				}
				return kQLReturnNoError;
			}
		}
#endif /* __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8 */
		/// Normal PNG, or other type
		CFStringRef filename = CFURLCopyLastPathComponent(url);
		CFDictionaryRef properties = createQLPreviewPropertiesForFile(url, url, filename);
		QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);
		CFRelease(properties);
		CFRelease(filename);

		return kQLReturnNoError;
	}
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
}
