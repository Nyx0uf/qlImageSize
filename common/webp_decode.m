//
//  webp_decode.m
//  qlImageSize
//
//  Created by @Nyx0uf on 30/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//


#import "webp_decode.h"
#import "decode.h"


#ifdef NYX_QL_SUPPORT_WEBP_DECODE
CF_RETURNS_RETAINED CGImageRef decode_webp_at_path(CFStringRef filepath, image_infos* infos)
{
	// Init WebP decoder
	WebPDecoderConfig webp_cfg;
	if (!WebPInitDecoderConfig(&webp_cfg))
		return NULL;

	// Read file
	uint8_t* buffer = NULL;
	const size_t file_size = read_file(filepath, &buffer);
	if (0 == file_size)
	{
		free(buffer);
		return NULL;
	}

	// Get image infos
	if (WebPGetFeatures(buffer, file_size, &webp_cfg.input) != VP8_STATUS_OK)
	{
		free(buffer);
		return NULL;
	}

	// Decode image, always RGBA
	webp_cfg.output.colorspace = webp_cfg.input.has_alpha ? MODE_rgbA : MODE_RGB;
	webp_cfg.options.use_threads = 1;
	WebPIDecoder* const idec = WebPIDecode(buffer, file_size, &webp_cfg);
	if (idec == NULL)
	{
		free(buffer);
		return NULL;
	}
	else
	{
		VP8StatusCode status = VP8_STATUS_OK;
		size_t done_size = 0;
		const size_t incr = 25165824; // 24MB, arbitrary chosen
		while (done_size < file_size)
		{
			size_t next_size = done_size + incr;
			if (next_size > file_size)
				next_size = file_size;
			status = WebPIUpdate(idec, buffer, next_size);
			if (status != VP8_STATUS_OK && status != VP8_STATUS_SUSPENDED)
				break;
			done_size = next_size;
		}
		WebPIDelete(idec);
	}
	free(buffer);

	const size_t width = (size_t)webp_cfg.input.width;
	const size_t height = (size_t)webp_cfg.input.height;
	if (infos != NULL)
	{
		infos->width = width;
		infos->height = height;
		infos->filesize = (size_t)file_size;
	}

	// Create CGImage
	CGDataProviderRef data_provider = CGDataProviderCreateWithData(NULL, webp_cfg.output.u.RGBA.rgba, webp_cfg.output.u.RGBA.size, NULL);
	if (data_provider == NULL)
		return NULL;
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | (webp_cfg.input.has_alpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNoneSkipLast);
	const size_t components = webp_cfg.input.has_alpha ? 4 : 3;
	CGImageRef img_ref = CGImageCreate(width, height, 8, components * 8, components * width, color_space, bitmapInfo, data_provider, NULL, false, kCGRenderingIntentDefault);

	CGColorSpaceRelease(color_space);
	CGDataProviderRelease(data_provider);

	return img_ref;
}
#endif /* NYX_QL_SUPPORT_WEBP_DECODE */

#ifdef NYX_MD_SUPPORT_WEBP_DECODE
bool get_webp_informations_for_filepath(CFStringRef filepath, image_infos* infos)
{
	WebPDecoderConfig webp_cfg;
	if (!WebPInitDecoderConfig(&webp_cfg))
		return false;

	// Read file
	uint8_t* buffer = NULL;
	const size_t size = read_file(filepath, &buffer);
	if (0 == size)
	{
		free(buffer);
		return false;
	}

	// Get file informations
	if (WebPGetFeatures(buffer, size, &webp_cfg.input) != VP8_STATUS_OK)
	{
		free(buffer);
		return false;
	}
	free(buffer);

	infos->width = (size_t)webp_cfg.input.width;
	infos->height = (size_t)webp_cfg.input.height;
	infos->has_alpha = (uint8_t)webp_cfg.input.has_alpha;
	infos->bit_depth = 8;
	infos->colorspace = (webp_cfg.input.format == 2) ? colorspace_rgb : colorspace_ycbcr; // lossy WebP, always YUV 4:2:0 | lossless WebP, always ARGB

	return true;
}
#endif /* NYX_MD_SUPPORT_WEBP_DECODE */
