//
//  GetMetadataForFile.m
//  qlImageSize
//
//  Created by @Nyx0uf on 20/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <CoreData/CoreData.h>
#import "Tools.h"
#import "decode.h"
#import "libbpg.h"


Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);


Boolean GetMetadataForFile(__unused void* thisInterface, CFMutableDictionaryRef attributes, __unused CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
	@autoreleasepool
	{
		NSString* filepath = (__bridge NSString*)pathToFile;
		NSString* extension = [[filepath pathExtension] lowercaseString];
		if ([extension isEqualToString:@"webp"] || [extension isEqualToString:@"pgm"] || [extension isEqualToString:@"ppm"] || [extension isEqualToString:@"pbm"] || [extension isEqualToString:@"bpg"])
		{
			if ([extension isEqualToString:@"webp"])
			{
				/* WebP */

				WebPDecoderConfig webp_cfg;
				if (!WebPInitDecoderConfig(&webp_cfg))
					return FALSE;

				// Read file
				uint8_t* buffer = NULL;
				const size_t size = read_file([filepath UTF8String], &buffer);
				if (0 == size)
				{
					free(buffer);
					return FALSE;
				}

				// Get file informations
				if (WebPGetFeatures(buffer, size, &webp_cfg.input) != VP8_STATUS_OK)
				{
					free(buffer);
					return FALSE;
				}
				free(buffer);

				NSMutableDictionary* attrs = (__bridge NSMutableDictionary*)attributes;
				attrs[(NSString*)kMDItemPixelWidth] = @(webp_cfg.input.width);
				attrs[(NSString*)kMDItemPixelHeight] = @(webp_cfg.input.height);
				attrs[(NSString*)kMDItemPixelCount] = @(webp_cfg.input.height * webp_cfg.input.width);
				attrs[(NSString*)kMDItemHasAlphaChannel] = (!webp_cfg.input.has_alpha) ? @NO : @YES;
				attrs[(NSString*)kMDItemBitsPerSample] = @8; // WebP is 8-bit
				if (webp_cfg.input.format == 2)
					attrs[(NSString*)kMDItemColorSpace] = @"RGB"; // lossless WebP, always ARGB
				else
					attrs[(NSString*)kMDItemColorSpace] = @"Y'CbCr"; // lossy WebP, always YUV 4:2:0
				return TRUE;
			}
			else if ([extension isEqualToString:@"bpg"])
			{
				/* bpg */

				// Read file
				uint8_t* buffer = NULL;
				const size_t size = read_file([filepath UTF8String], &buffer);
				if (0 == size)
				{
					free(buffer);
					return FALSE;
				}

				// Decode image
				BPGDecoderContext* bpg_ctx = bpg_decoder_open();
				int ret = bpg_decoder_decode(bpg_ctx, buffer, (int)size);
				free(buffer);
				if (ret < 0)
				{
					bpg_decoder_close(bpg_ctx);
					return FALSE;
				}

				// Get image infos
				BPGImageInfo img_info_s, *img_info = &img_info_s;
				bpg_decoder_get_info(bpg_ctx, img_info);
				NSMutableDictionary* attrs = (__bridge NSMutableDictionary*)attributes;
				attrs[(NSString*)kMDItemPixelWidth] = @(img_info->width);
				attrs[(NSString*)kMDItemPixelHeight] = @(img_info->height);
				attrs[(NSString*)kMDItemPixelCount] = @(img_info->height * img_info->width);
				attrs[(NSString*)kMDItemHasAlphaChannel] = (!img_info->has_alpha) ? @NO : @YES;
				attrs[(NSString*)kMDItemBitsPerSample] = @(img_info->bit_depth);
				const BPGColorSpaceEnum color_space = (BPGColorSpaceEnum)img_info->color_space;
				NSString* color_space_string = @"Undefined";
				switch (color_space)
				{
					case BPG_CS_YCbCr:
						color_space_string = @"Y'CbCr";
						break;
					case BPG_CS_RGB:
						color_space_string = @"RGB";
						break;
					case BPG_CS_YCgCo:
						color_space_string = @"Y'CgCo";
						break;
					case BPG_CS_YCbCr_BT709:
						color_space_string = @"BT.709";
						break;
					case BPG_CS_YCbCr_BT2020:
						color_space_string = @"BT.2020";
						break;
					default:
						color_space_string = @"Undefined";
						break;
				}
				attrs[(NSString*)kMDItemColorSpace] = color_space_string;
				bpg_decoder_close(bpg_ctx);

				return TRUE;
			}
			else
			{
				/* Portable Pixmap */

				// Read file
				uint8_t* buffer = NULL;
				const size_t size = read_file([filepath UTF8String], &buffer);
				if (0 == size)
				{
					free(buffer);
					return FALSE;
				}

				// Check if Portable Pixmap
				if ((char)buffer[0] != 'P' && ((char)buffer[1] != '1' || (char)buffer[1] != '2' || (char)buffer[1] != '3' || (char)buffer[1] != '4' || (char)buffer[1] != '5' || (char)buffer[1] != '6'))
				{
					free(buffer);
					return FALSE;
				}

				// Get width
				size_t index = 3, i = 0;
				char ctmp[8] = {0x00};
				char c = 0x00;
				while ((c = (char)buffer[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
					ctmp[i++] = c;
				const size_t width = (size_t)atol(ctmp);

				// Get height
				i = 0;
				memset(ctmp, 0x00, 8);
				while ((c = (char)buffer[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
					ctmp[i++] = c;
				const size_t height = (size_t)atol(ctmp);

				free(buffer);

				NSMutableDictionary* attrs = (__bridge NSMutableDictionary*)attributes;
				attrs[(NSString*)kMDItemPixelWidth] = @(width);
				attrs[(NSString*)kMDItemPixelHeight] = @(height);
				attrs[(NSString*)kMDItemPixelCount] = @(height * width);
				attrs[(NSString*)kMDItemHasAlphaChannel] = @NO;
				attrs[(NSString*)kMDItemBitsPerSample] = @8;
				attrs[(NSString*)kMDItemColorSpace] = @"RGB";
				return TRUE;
			}
		}
	}
    
	return TRUE;
}
