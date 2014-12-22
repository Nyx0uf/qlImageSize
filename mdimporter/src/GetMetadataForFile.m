//
//  GetMetadataForFile.m
//  qlImageSize
//
//  Created by @Nyx0uf on 20/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <CoreData/CoreData.h>
#import "decode.h"
#import "libbpg.h"


Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);


Boolean GetMetadataForFile(__unused void* thisInterface, CFMutableDictionaryRef attributes, __unused CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
	@autoreleasepool
	{
		NSString* filepath = (__bridge NSString*)pathToFile;
		NSString* urlExtension = [[filepath pathExtension] lowercaseString];
		if ([urlExtension isEqualToString:@"webp"] || [urlExtension isEqualToString:@"pgm"] || [urlExtension isEqualToString:@"ppm"] || [urlExtension isEqualToString:@"pbm"] || [urlExtension isEqualToString:@"bpg"])
		{
			if ([urlExtension isEqualToString:@"webp"])
			{
				/* WebP */
				WebPDecoderConfig config;
				if (!WebPInitDecoderConfig(&config))
					return FALSE;

				// Open the file, get its size and read it
				FILE* f = fopen([filepath UTF8String], "rb");
				if (NULL == f)
					return FALSE;

				fseek(f, 0, SEEK_END);
				const size_t size = (size_t)ftell(f);
				fseek(f, 0, SEEK_SET);

				uint8_t* buffer = (uint8_t*)malloc(size);
				const size_t nb = fread(buffer, 1, size, f);
				fclose(f);
				if (nb != size)
				{
					free(buffer);
					return FALSE;
				}

				// Get file informations
				if (WebPGetFeatures(buffer, size, &config.input) != VP8_STATUS_OK)
				{
					free(buffer);
					return FALSE;
				}
				free(buffer);

				NSMutableDictionary* attrs = (__bridge NSMutableDictionary*)attributes;
				attrs[(NSString*)kMDItemPixelWidth] = @(config.input.width);
				attrs[(NSString*)kMDItemPixelHeight] = @(config.input.height);
				attrs[(NSString*)kMDItemPixelCount] = @(config.input.height * config.input.width);
				attrs[(NSString*)kMDItemHasAlphaChannel] = (!config.input.has_alpha) ? @NO : @YES;
				attrs[(NSString*)kMDItemBitsPerSample] = @8; // WebP is 8-bit
				if (config.input.format == 2)
					attrs[(NSString*)kMDItemColorSpace] = @"RGB"; // lossless WebP, always ARGB
				else
					attrs[(NSString*)kMDItemColorSpace] = @"Y'CbCr"; // lossy WebP, always YUV 4:2:0
				return TRUE;
			}
			else if ([urlExtension isEqualToString:@"bpg"])
			{
				/* bpg */
				// Open the file, get its size and read it
				FILE* f = fopen([filepath UTF8String], "rb");
				if (NULL == f)
					return FALSE;

				fseek(f, 0, SEEK_END);
				const size_t size = (size_t)ftell(f);
				fseek(f, 0, SEEK_SET);

				uint8_t* buffer = (uint8_t*)malloc(size);
				const size_t nb = fread(buffer, 1, size, f);
				fclose(f);
				if (nb != size)
				{
					free(buffer);
					return FALSE;
				}

				// Decode image
				BPGDecoderContext* img = bpg_decoder_open();
				int ret = bpg_decoder_decode(img, buffer, (int)size);
				free(buffer);
				if (ret < 0)
				{
					bpg_decoder_close(img);
					return FALSE;
				}

				// Get image infos
				BPGImageInfo img_info_s, *img_info = &img_info_s;
				bpg_decoder_get_info(img, img_info);
				NSMutableDictionary* attrs = (__bridge NSMutableDictionary*)attributes;
				attrs[(NSString*)kMDItemPixelWidth] = @(img_info->width);
				attrs[(NSString*)kMDItemPixelHeight] = @(img_info->height);
				attrs[(NSString*)kMDItemPixelCount] = @(img_info->height * img_info->width);
				attrs[(NSString*)kMDItemHasAlphaChannel] = (!img_info->has_alpha) ? @NO : @YES;
				attrs[(NSString*)kMDItemBitsPerSample] = @(img_info->bit_depth);
				const BPGColorSpaceEnum cs = (BPGColorSpaceEnum)img_info->color_space;
				NSString* css = @"Undefined";
				switch (cs)
				{
					case BPG_CS_YCbCr:
						css = @"Y'CbCr";
						break;
					case BPG_CS_RGB:
						css = @"RGB";
						break;
					case BPG_CS_YCgCo:
						css = @"Y'CgCo";
						break;
					case BPG_CS_YCbCr_BT709:
						css = @"BT.709";
						break;
					case BPG_CS_YCbCr_BT2020:
						css = @"BT.2020";
						break;
					default:
						css = @"Undefined";
						break;
				}
				attrs[(NSString*)kMDItemColorSpace] = css;
				bpg_decoder_close(img);

				return TRUE;
			}
			else
			{
				/* Portable Pixmap */
				// Open the file, get its size and read it
				FILE* f = fopen([filepath UTF8String], "rb");
				if (NULL == f)
					return FALSE;

				fseek(f, 0, SEEK_END);
				const size_t size = (size_t)ftell(f);
				fseek(f, 0, SEEK_SET);

				uint8_t* buffer = (uint8_t*)malloc(size);
				const size_t nb = fread(buffer, 1, size, f);
				fclose(f);
				if (nb != size)
				{
					free(buffer);
					return FALSE;
				}

				// Check if Portable Pixmap
				if ((char)buffer[0] != 'P')
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
