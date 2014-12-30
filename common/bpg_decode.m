//
//  bpg_decode.m
//  qlImageSize
//
//  Created by @Nyx0uf on 30/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "bpg_decode.h"
#import "libbpg.h"


CF_RETURNS_RETAINED CGImageRef decode_bpg_at_path(CFStringRef filepath, image_infos* infos)
{
	// Read file
	uint8_t* buffer = NULL;
	const size_t file_size = read_file(filepath, &buffer);
	if (0 == file_size)
	{
		free(buffer);
		return NULL;
	}

	// Decode image
	BPGDecoderContext* bpg_ctx = bpg_decoder_open();
	int ret = bpg_decoder_decode(bpg_ctx, buffer, (int)file_size);
	free(buffer);
	if (ret < 0)
	{
		bpg_decoder_close(bpg_ctx);
		return NULL;
	}

	// Get image infos
	BPGImageInfo img_info_s, *img_info = &img_info_s;
	bpg_decoder_get_info(bpg_ctx, img_info);
	const size_t w = (size_t)img_info->width;
	const size_t h = (size_t)img_info->height;

	// Always output in RGBA format
	const size_t stride = 4 * w;
	const size_t img_size = stride * h;
	uint8_t* rgb_buffer = (uint8_t*)malloc(img_size);
	size_t idx = 0;
	bpg_decoder_start(bpg_ctx, BPG_OUTPUT_FORMAT_RGBA32);
	for (size_t y = 0; y < h; y++)
	{
		bpg_decoder_get_line(bpg_ctx, rgb_buffer + idx);
		idx += stride;
	}
	bpg_decoder_close(bpg_ctx);

	if (infos != NULL)
	{
		infos->width = w;
		infos->height = h;
		infos->filesize = file_size;
	}

	// Create CGImage
	CGDataProviderRef data_provider = CGDataProviderCreateWithData(NULL, rgb_buffer, img_size, NULL);
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGImageRef img_ref = CGImageCreate(w, h, 8, 32, stride, color_space, kCGBitmapByteOrderDefault | kCGImageAlphaNone, data_provider, NULL, true, kCGRenderingIntentDefault);
	CGColorSpaceRelease(color_space);
	CGDataProviderRelease(data_provider);
	free(rgb_buffer);
	return img_ref;
}

bool get_bpg_informations_for_filepath(CFStringRef filepath, image_infos* infos)
{
	// Read file
	uint8_t* buffer = NULL;
	const size_t size = read_file(filepath, &buffer);
	if (0 == size)
	{
		free(buffer);
		return false;
	}

	// Decode image
	BPGDecoderContext* bpg_ctx = bpg_decoder_open();
	int ret = bpg_decoder_decode(bpg_ctx, buffer, (int)size);
	free(buffer);
	if (ret < 0)
	{
		bpg_decoder_close(bpg_ctx);
		return false;
	}

	// Get image infos
	BPGImageInfo img_info_s, *img_info = &img_info_s;
	bpg_decoder_get_info(bpg_ctx, img_info);
	infos->width = (size_t)img_info->width;
	infos->height = (size_t)img_info->height;
	infos->has_alpha = (uint8_t)img_info->has_alpha;
	infos->bit_depth = (uint8_t)img_info->bit_depth;
	colorspace_t cs = colorspace_unknown;
	const BPGColorSpaceEnum color_space = (BPGColorSpaceEnum)img_info->color_space;
	switch (color_space)
	{
		case BPG_CS_RGB:
			cs = colorspace_rgb;
			break;
		case BPG_CS_YCbCr:
			cs = colorspace_ycbcr;
			break;
		case BPG_CS_YCgCo:
			cs = colorspace_ycgco;
			break;
		case BPG_CS_YCbCr_BT709:
			cs = colorspace_bt709;
			break;
		case BPG_CS_YCbCr_BT2020:
			cs = colorspace_bt2020;
			break;
		default:
			cs = colorspace_unknown;
	}
	infos->colorspace = cs;
	bpg_decoder_close(bpg_ctx);

	return true;
}
