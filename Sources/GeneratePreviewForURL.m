//
//  GeneratePreviewForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "Tools.h"
#import <Foundation/NSURL.h>
#import <AppKit/AppKit.h>


#if (__MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8)
#import "NYXPNGTools.h"
#endif /* __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8 */


#define NYX_FONTSIZE 18.0f


OSStatus GeneratePreviewForURL(void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */
OSStatus GeneratePreviewForURL(__unused void* thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options)
{
	@autoreleasepool
	{
#if (__MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8)
		// Check if the image is a PNG
		if (CFStringCompare(contentTypeUTI, kUTTypePNG, kCFCompareCaseInsensitive) == kCFCompareEqualTo)
		{
			const char* path = [[(__bridge NSURL*)url path] cStringUsingEncoding:NSUTF8StringEncoding];
			int error = 0;
			if (npt_is_apple_crushed_png(path, &error))
			{
				if (QLPreviewRequestIsCancelled(preview))
					return kQLReturnNoError;
				// Uncrush the PNG
				unsigned int size = 0;
				UInt8* pngData = npt_create_uncrushed_from_file(path, &size, &error);
				if (NULL == pngData)
				{
					NSLog(@"[-] qlImageSize: Failed to create uncrushed png from '%@' : %s", url, npt_error_message(error));
				}
				else
				{
					if (QLPreviewRequestIsCancelled(preview))
					{
						free(pngData);
						return kQLReturnNoError;
					}
					CFDataRef uncrushed = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pngData, size, kCFAllocatorDefault);
					if (uncrushed != NULL)
					{
						// Create the properties dic
						CFStringRef filename = CFURLCopyLastPathComponent(url);
						CFDictionaryRef properties = createQLPreviewPropertiesForFile(url, uncrushed, filename, NULL, NULL);
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
		/* As of 10.8 crushed PNGs are natively handled, so the stuff above is useless */
		CFStringRef filename = CFURLCopyLastPathComponent(url);
	
		// Kinda ugly but whatever
		CGSize imgSize;
		CGImageRef cgImg = NULL;
		CFDictionaryRef properties = createQLPreviewPropertiesForFile(url, url, filename, &imgSize, &cgImg);

		// Create the string containing dimensions
		NSString* strDimensions = [[NSString alloc] initWithFormat:@"%.fx%.f", imgSize.width, imgSize.height];

		// Minimum size for the string
		CGSize minSize = [strDimensions sizeWithAttributes:@{NSFontAttributeName : [NSFont fontWithName:@"Helvetica" size:NYX_FONTSIZE]}];
		minSize.width = ceil(minSize.width);
		minSize.height = ceil(minSize.height);
		// Bitmap context dimensions, 20px height margin for text should be good
		const CGSize sizeCtx = (CGSize){.width = ((imgSize.width < minSize.width) ? minSize.width : imgSize.width), .height = ((imgSize.height < minSize.height) ? minSize.height : imgSize.height) + 20.0f};

		// Bitmap context render the size at the bottom
		CGContextRef ctx = QLPreviewRequestCreateContext(preview, sizeCtx, true, NULL);
		if (ctx != NULL)
		{
			// Draw image at top, x-centered
			if (imgSize.width < minSize.width)
				CGContextDrawImage(ctx, (CGRect){.origin.x = (minSize.width - imgSize.width) * 0.5f, .origin.y = 20.0f, .size = imgSize}, cgImg);
			else
				CGContextDrawImage(ctx, (CGRect){.origin.x = 0.0f, .origin.y = 20.0f, .size = imgSize}, cgImg);
			// Select font/color
			CGColorRef blackColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
			CGContextSetFillColorWithColor(ctx, blackColor);
			CGContextSelectFont(ctx, "Helvetica", NYX_FONTSIZE, kCGEncodingMacRoman);
			CGColorRelease(blackColor);
			// Draw text
			const CGFloat x = (imgSize.width < minSize.width) ? 0.0f : (imgSize.width - minSize.width) * 0.5f;
			CGContextShowTextAtPoint(ctx, x, 0.0f, [strDimensions cStringUsingEncoding:NSASCIIStringEncoding], [strDimensions length]);
			// Will render the bitmap into the QL window, but no titlebar modification, it will need to convert the img as a CFData blob etc, too lazy atm.
			QLPreviewRequestFlushContext(preview, ctx);
			CGContextRelease(ctx);
		}
		else
		{
			// Some kind of error, fallback
			QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, properties);
		}

		CGImageRelease(cgImg);
		CFRelease(properties);
		CFRelease(filename);

		return kQLReturnNoError;
	}
}

void CancelPreviewGeneration(__unused void* thisInterface, __unused QLPreviewRequestRef preview)
{
}
