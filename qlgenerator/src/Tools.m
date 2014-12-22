//
//  Tools.m
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import "Tools.h"
#import <sys/stat.h>
#import <sys/types.h>
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>
#import <CommonCrypto/CommonDigest.h>
#import "libbpg.h"
#import "decode.h"


typedef struct _nyx_rgb_pixel_struct {
	uint8_t r;
	uint8_t g;
	uint8_t b;
} rgb_pixel;


/* Private functions declarations */
static void* _decode_pbm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height);
static void* _decode_pgm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height);
static void* _decode_ppm(const uint8_t* bytes, const size_t size, size_t* width, size_t* height);
static size_t _get_file_size(CFURLRef url);


#pragma mark - Public
void properties_for_file(CFURLRef url, size_t* width, size_t* height, size_t* file_size)
{
	// Create the image source
	*width = 0, *height = 0, *file_size = 0;
	CGImageSourceRef img_src = CGImageSourceCreateWithURL(url, NULL);
	if (NULL == img_src)
		return;

	// Copy images properties
	CFDictionaryRef img_properties = CGImageSourceCopyPropertiesAtIndex(img_src, 0, NULL);
	if (NULL == img_properties)
	{
		CFRelease(img_src);
		return;
	}

	// Get image width
	CFNumberRef w = CFDictionaryGetValue(img_properties, kCGImagePropertyPixelWidth);
	CFNumberGetValue(w, kCFNumberSInt64Type, width);
	// Get image height
	CFNumberRef h = CFDictionaryGetValue(img_properties, kCGImagePropertyPixelHeight);
	CFNumberGetValue(h, kCFNumberSInt64Type, height);
	CFRelease(img_properties);

	CFRelease(img_src);

	// Get the filesize, because it's not always present in the image properties dictionary :/
	*file_size = _get_file_size(url);
}

size_t read_file(const char* filepath, uint8_t** buffer)
{
	// Open the file, get its size and read it
	FILE* f = fopen(filepath, "rb");
	if (NULL == f)
		return 0;

	fseek(f, 0, SEEK_END);
	const size_t file_size = (size_t)ftell(f);
	fseek(f, 0, SEEK_SET);

	*buffer = (uint8_t*)malloc(file_size);
	if (NULL == (*buffer))
	{
		fclose(f);
		return 0;
	}
	const size_t read_size = fread(*buffer, 1, file_size, f);
	fclose(f);
	if (read_size != file_size)
	{
		free(*buffer), *buffer = NULL;
		return 0;
	}

	return file_size;
}

CF_RETURNS_RETAINED CGImageRef decode_webp(CFURLRef url, size_t* width, size_t* height, size_t* file_size)
{
	*width = 0, *height = 0, *file_size = 0;

	// Init WebP decoder
	WebPDecoderConfig webp_cfg;
	if (!WebPInitDecoderConfig(&webp_cfg))
		return NULL;

	// Read file
	uint8_t* buffer = NULL;
	*file_size = read_file([[(__bridge NSURL*)url path] UTF8String], &buffer);
	if (0 == (*file_size))
	{
		free(buffer);
		return NULL;
	}

	// Get image infos
	if (WebPGetFeatures(buffer, *file_size, &webp_cfg.input) != VP8_STATUS_OK)
	{
		free(buffer);
		return NULL;
	}
	*width = (size_t)webp_cfg.input.width;
	*height = (size_t)webp_cfg.input.height;

	// Decode image, always RGBA
	webp_cfg.output.colorspace = MODE_rgbA;
	if (WebPDecode(buffer, *file_size, &webp_cfg) != VP8_STATUS_OK)
	{
		free(buffer);
		return NULL;
	}
	free(buffer);

	// Create CGImage
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(webp_cfg.output.u.RGBA.rgba, (size_t)webp_cfg.input.width, (size_t)webp_cfg.input.height, 8, 4 * (size_t)webp_cfg.input.width, color_space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(color_space);
	WebPFreeDecBuffer(&webp_cfg.output);
	CGImageRef img_ref = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
	return img_ref;
}

CF_RETURNS_RETAINED CGImageRef decode_bpg(CFURLRef url, size_t* width, size_t* height, size_t* file_size)
{
	*width = 0, *height = 0, *file_size = 0;

	// Read file
	uint8_t* buffer = NULL;
	*file_size = read_file([[(__bridge NSURL*)url path] UTF8String], &buffer);
	if (0 == (*file_size))
	{
		free(buffer);
		return NULL;
	}

	// Decode image
	BPGDecoderContext* bpg_ctx = bpg_decoder_open();
	int ret = bpg_decoder_decode(bpg_ctx, buffer, (int)(*file_size));
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
	*width = w;
	*height = h;

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

	// Create CGImage
	CGDataProviderRef data_provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)[[NSData alloc] initWithBytesNoCopy:rgb_buffer length:img_size freeWhenDone:NO]);
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGImageRef img_ref = CGImageCreate(w, h, 8, 32, stride, color_space, kCGBitmapByteOrderDefault | kCGImageAlphaNone, data_provider, NULL, true, kCGRenderingIntentDefault);
	CGColorSpaceRelease(color_space);
	CGDataProviderRelease(data_provider);
	free(rgb_buffer);
	return img_ref;
}

CF_RETURNS_RETAINED CGImageRef decode_portable_pixmap(CFURLRef url, size_t* width, size_t* height, size_t* file_size)
{
	*width = 0, *height = 0, *file_size = 0;

	// Read file
	uint8_t* buffer = NULL;
	*file_size = read_file([[(__bridge NSURL*)url path] UTF8String], &buffer);
	if (0 == (*file_size))
	{
		free(buffer);
		return NULL;
	}

	// Identify type (handle binary only)
	if ((char)buffer[0] != 'P')
		return NULL;

	// Only handle binary version for now
	uint8_t* rgb_buffer = NULL;
	const char idd = (char)buffer[1];
	if (idd == '4'/* || idd == '1'*/) // pbm
		rgb_buffer = _decode_pbm(buffer, *file_size, width, height);
	else if (idd == '5'/* || idd == '2'*/) // pgm
		rgb_buffer = _decode_pgm(buffer, *file_size, width, height);
	else if (idd == '6'/* || idd == '3'*/) // ppm
		rgb_buffer = _decode_ppm(buffer, *file_size, width, height);
	else
	{
		free(buffer);
		return NULL;
	}
	free(buffer);

	// Create CGImage
	CGDataProviderRef data_provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)[[NSData alloc] initWithBytesNoCopy:rgb_buffer length:((*file_size) * 3) freeWhenDone:NO]);
	CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
	CGImageRef img_ref = CGImageCreate(*width, *height, 8, 24, 3 * *width, color_space, kCGBitmapByteOrderDefault | kCGImageAlphaNone, data_provider, NULL, true, kCGRenderingIntentDefault);
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
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	*width = (size_t)atol(ctmp);

	// Get height
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	*height = (size_t)atol(ctmp);

	// 1 byte = 8 px
	rgb_pixel* rgb_buffer = (rgb_pixel*)malloc(((size - index + 1) * 8) * 3);
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
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	*width = (size_t)atol(ctmp);

	// Get height
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	*height = (size_t)atol(ctmp);

	// Get max gray value (max is 65535), but we only handle 8-bit so over 255 is a no-no
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	const size_t max_val = (size_t)atol(ctmp);
	if (max_val > 255)
		return NULL; // 16-bit, ignore.

	// Convert to RGB
	const size_t acutal_size = (size - index + 1);
	rgb_pixel* rgb_buffer = (rgb_pixel*)malloc(sizeof(rgb_pixel) * acutal_size);
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
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	*width = (size_t)atol(ctmp);

	// Get height
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	*height = (size_t)atol(ctmp);

	// Get max component value (max is 65535), but we only handle 8-bit so over 255 is a no-no
	i = 0;
	memset(ctmp, 0x00, 8);
	while ((c = (char)bytes[index++]) && (c != ' ' && c != '\r' && c != '\n' && c != '\t'))
		ctmp[i++] = c;
	const size_t max_val = (size_t)atol(ctmp);
	if (max_val > 255)
		return NULL; // 16-bit, ignore.

	void* buffer = NULL;
	const size_t acutal_size = (size - index + 1);
	const float ratio = (float)max_val / 255.0f;
	if ((int)ratio == 1)
	{
		// Got the same ratio, just have to make a copy
		buffer = (uint8_t*)malloc(sizeof(uint8_t) * acutal_size);
		memcpy(buffer, &(bytes[index]), acutal_size);
	}
	else
	{
		// Moronic case, whoever does this deserve to die
		float* data_as_float = (float*)malloc(sizeof(float) * acutal_size);
		buffer = (uint8_t*)malloc(sizeof(uint8_t) * acutal_size);
		vDSP_vfltu8(&(bytes[index]), 1, data_as_float, 1, acutal_size);
		vDSP_vsdiv(data_as_float, 1, &ratio, data_as_float, 1, acutal_size);
		vDSP_vfixu8(data_as_float, 1, buffer, 1, acutal_size);
		free(data_as_float);
		/*buf = (rgb_pixel*)malloc(siz);
		i = 0;
		for (size_t j = index; j < size; j += 3)
		{
			const uint8_t r = (uint8_t)((float)bytes[j] / ratio);
			const uint8_t g = (uint8_t)((float)bytes[j + 1] / ratio);
			const uint8_t b = (uint8_t)((float)bytes[j + 2] / ratio);
			((rgb_pixel*)buf)[i++] = (rgb_pixel){.r = r, .g = g, .b = b};
		}*/
	}

	return buffer;
}

static size_t _get_file_size(CFURLRef url)
{
	UInt8 buf[4096] = {0x00};
	CFURLGetFileSystemRepresentation(url, true, buf, 4096);
	struct stat st;
	stat((const char*)buf, &st);
	return (size_t)st.st_size;
}
