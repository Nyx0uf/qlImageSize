//
//  netpbm_decode.m
//  qlImageSize
//
//  Created by @Nyx0uf on 30/12/14.
//  Copyright (c) 2014 Nyx0uf. All rights reserved.
//


#import "netpbm_decode.h"


#ifdef NYX_MD_SUPPORT_NETPBM_DECODE
bool get_netpbm_informations_for_filepath(CFStringRef filepath, image_infos* infos)
{
	// Read file
	uint8_t* buffer = NULL;
	const size_t size = read_file(filepath, &buffer);
	if (0 == size)
	{
		free(buffer);
		return false;
	}

	// Check if Portable Pixmap
	if ((char)buffer[0] != 'P' && ((char)buffer[1] != '1' || (char)buffer[1] != '2' || (char)buffer[1] != '3' || (char)buffer[1] != '4' || (char)buffer[1] != '5' || (char)buffer[1] != '6'))
	{
		free(buffer);
		return false;
	}

	// Get width
	size_t index = 3, i = 0;
	char ctmp[8] = {0x00};
	char c = 0x00;
	while ((c = (char)buffer[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	infos->width = (size_t)atol(ctmp);

	// Get height
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)buffer[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	infos->height = (size_t)atol(ctmp);

	infos->has_alpha = 0;
	infos->bit_depth = 8;
	infos->colorspace = colorspace_rgb;

	free(buffer);

	return true;
}
#endif /* NYX_MD_SUPPORT_NETPBM_DECODE */

#ifdef NYX_QL_SUPPORT_NETPBM_DECODE

#import <Accelerate/Accelerate.h>

typedef struct _nyx_rgb_pixel_struct {
	uint8_t r;
	uint8_t g;
	uint8_t b;
} rgb_pixel;

/* Private functions declarations */
static void* _decode_pbm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height);
static void* _decode_pgm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height);
static void* _decode_ppm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height);

CF_RETURNS_RETAINED CGImageRef decode_netpbm_at_path(CFStringRef filepath,  image_infos* infos)
{
	// Read file
	uint8_t* buffer = NULL;
	const size_t file_size = read_file(filepath, &buffer);
	if (0 == file_size)
	{
		free(buffer);
		return NULL;
	}

	// Identify type (handle binary only)
	if ((char)buffer[0] != 'P')
	{
		free(buffer);
		return NULL;
	}

	// Only handle binary version for now
	uint8_t* rgb_buffer = NULL;
	size_t width = 0, height = 0;
	const char idd = (char)buffer[1];
	if (idd == '4'/* || idd == '1'*/) // pbm
		rgb_buffer = _decode_pbm(buffer, file_size, &width, &height);
	else if (idd == '5'/* || idd == '2'*/) // pgm
		rgb_buffer = _decode_pgm(buffer, file_size, &width, &height);
	else if (idd == '6'/* || idd == '3'*/) // ppm
		rgb_buffer = _decode_ppm(buffer, file_size, &width, &height);
	else
	{
		free(buffer);
		return NULL;
	}
	free(buffer);

	if (infos != NULL)
	{
		infos->width = width;
		infos->height = height;
		infos->filesize = file_size;
	}

	// Create CGImage
	CGDataProviderRef data_provider = CGDataProviderCreateWithData(NULL, rgb_buffer, width * height * 3, NULL);
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGImageRef img_ref = CGImageCreate(width, height, 8, 24, 3 * width, color_space, kCGBitmapByteOrderDefault | kCGImageAlphaNone, data_provider, NULL, true, kCGRenderingIntentDefault);
	CGColorSpaceRelease(color_space);
	CGDataProviderRelease(data_provider);
	free(rgb_buffer);
	return img_ref;
}

#pragma mark - Private
static void* _decode_pbm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height)
{
	// TODO: FIX cause it's bugged :>
	// format, where • is a separator (space, tab, newline)
	// P4•WIDTH•HEIGHT

	// Get width
	size_t index = 3, i = 0;
	char ctmp[8] = {0x00};
	char c = 0x00;
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	*width = (size_t)atol(ctmp);

	// Get height
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	*height = (size_t)atol(ctmp);

	// 1 byte = 8 px
	//rgb_pixel* rgb_buffer = (rgb_pixel*)malloc(((size - index + 1) * 8) * 3);
	rgb_pixel* rgb_buffer = (rgb_pixel*)malloc((*width) * (*height) * 3);
	i = 0;
	while (index < size)
	{
		uint8_t b = bytes[index++];
		for (int a = 8; a >= 1; a--)
		{
			uint8_t tmp = ((b >> a) & 0x01);
			tmp = (0 == tmp) ? 255 : 0;
			rgb_buffer[i++] = (rgb_pixel){tmp, tmp, tmp};
		}
	}

	return rgb_buffer;
}

static void* _decode_pgm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height)
{
	// format, where • is a separator (space, tab, newline)
	// P5•WIDTH•HEIGHT•MAX_GRAY_VAL

	// Get width
	size_t index = 3, i = 0;
	char ctmp[8] = {0x00};
	char c = 0x00;
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	*width = (size_t)atol(ctmp);

	// Get height
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	*height = (size_t)atol(ctmp);

	// Get max gray value (max is 65535), but we only handle 8-bit so over 255 is a no-no
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	const size_t max_val = (size_t)atol(ctmp);
	if (max_val > 255)
		return NULL; // 16-bit, ignore.

	// Convert to RGB
	const size_t actual_size = (size - index + 1);
	rgb_pixel* rgb_buffer = (rgb_pixel*)malloc(sizeof(rgb_pixel) * actual_size);
	const float ratio = (float)max_val / 255.0f;
	i = 0;
	if ((int)ratio == 1)
	{
		while (index < size)
		{
			const uint8_t b = bytes[index++];
			rgb_buffer[i++] = (rgb_pixel){b, b, b};
		}
	}
	else
	{
		while (index < size)
		{
			const uint8_t b = (uint8_t)((float)bytes[index++] / ratio);
			rgb_buffer[i++] = (rgb_pixel){b, b, b};
		}
	}

	return rgb_buffer;
}

static void* _decode_ppm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height)
{
	// format, where • is a separator (space, tab, newline)
	// P6•WIDTH•HEIGHT•MAX_VAL

	// Get width
	size_t index = 3, i = 0;
	char ctmp[8] = {0x00};
	char c = 0x00;
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	*width = (size_t)atol(ctmp);

	// Get height
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	*height = (size_t)atol(ctmp);

	// Get max component value (max is 65535), but we only handle 8-bit so over 255 is a no-no
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (!isspace(c)))
		ctmp[i++] = c;
	const size_t max_val = (size_t)atol(ctmp);
	if (max_val > 255)
		return NULL; // 16-bit, ignore.

	void* buffer = NULL;
	const size_t actual_size = (size - index + 1);
	const float ratio = (float)max_val / 255.0f;
	if ((int)ratio == 1)
	{
		// Got the same ratio, just have to make a copy
		buffer = (uint8_t*)malloc(sizeof(uint8_t) * actual_size);
		memcpy(buffer, &(bytes[index]), actual_size);
	}
	else
	{
		// Moronic case, whoever does this deserve to die
		float* data_as_float = (float*)malloc(sizeof(float) * actual_size);
		buffer = (uint8_t*)malloc(sizeof(uint8_t) * actual_size);
		vDSP_vfltu8(&(bytes[index]), 1, data_as_float, 1, actual_size);
		vDSP_vsdiv(data_as_float, 1, &ratio, data_as_float, 1, actual_size);
		vDSP_vfixu8(data_as_float, 1, buffer, 1, actual_size);
		free(data_as_float);
	}

	return buffer;
}

#endif /* NYX_QL_SUPPORT_NETPBM_DECODE */
