//
//  GenerateThumbnailForURL.c
//  qlImageSize
//
//  Created by @Nyx0uf on 31/01/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <QuickLook/QuickLook.h>
#import "bpg_decode.h"
#import "webp_decode.h"
#import "netpbm_decode.h"


OSStatus GenerateThumbnailForURL(void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);


OSStatus GenerateThumbnailForURL(__unused void* thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, __unused CFDictionaryRef options, __unused CGSize maxSize)
{
	@autoreleasepool
	{
		// Get the UTI properties
		NSDictionary* uti_declarations = (__bridge_transfer NSDictionary*)UTTypeCopyDeclaration(contentTypeUTI);

		// Get the extensions corresponding to the image UTI, for some UTI there can be more than 1 extension (ex image.jpeg = jpeg, jpg...)
		// If it fails for whatever reason fallback to the filename extension
		id extensions = uti_declarations[(__bridge NSString*)kUTTypeTagSpecificationKey][(__bridge NSString*)kUTTagClassFilenameExtension];
		NSString* extension = ([extensions isKindOfClass:[NSArray class]]) ? extensions[0] : extensions;
		if (nil == extension)
			extension = ([(__bridge NSURL*)url pathExtension] != nil) ? [(__bridge NSURL*)url pathExtension] : @"";
		extension = [extension lowercaseString];

		// Create the properties dic
		CFTypeRef keys[1] = {kQLThumbnailPropertyExtensionKey};
		CFTypeRef values[1] = {(__bridge CFStringRef)extension};
		CFDictionaryRef properties = CFDictionaryCreate(kCFAllocatorDefault, (const void**)keys, (const void**)values, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

		// Check by extension because it's highly unprobable that an UTI for these formats is declared
		// the simplest way to declare one is creating a dummy automator app and adding imported/exported UTI conforming to public.image
		if ([extension isEqualToString:@"webp"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pbm"] || [extension isEqualToString:@"bpg"])
		{
			if (!QLThumbnailRequestIsCancelled(thumbnail))
			{
				// 1. decode the image
				size_t width = 0, height = 0, file_size = 0;
				CGImageRef img_ref = NULL;
				CFStringRef filepath = CFURLCopyPath(url);
				if ([extension isEqualToString:@"webp"])
					img_ref = decode_webp_at_path(filepath, &width, &height, &file_size);
				else if ([extension isEqualToString:@"bpg"])
					img_ref = decode_bpg_at_path(filepath, &width, &height, &file_size);
				else
					img_ref = decode_netpbm_at_path(filepath, &width, &height, &file_size);
				if (filepath != NULL)
					CFRelease(filepath);

				// 2. render it
				if (img_ref != NULL)
				{
					QLThumbnailRequestSetImage(thumbnail, img_ref, properties);
					CGImageRelease(img_ref);
				}
				else
					QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
			}
			else
				QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);
		}
		else
			QLThumbnailRequestSetImageAtURL(thumbnail, url, properties);

		if (properties != NULL)
			CFRelease(properties);
	}
	return kQLReturnNoError;
}

void CancelThumbnailGeneration(__unused void* thisInterface, __unused QLThumbnailRequestRef thumbnail)
{
}
