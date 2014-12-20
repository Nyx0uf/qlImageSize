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
void properties_for_file(CFURLRef url, size_t* width, size_t* height, size_t* fileSize)
{
	// Create the image source
	*width = 0, *height = 0, *fileSize = 0;
	CGImageSourceRef imgSrc = CGImageSourceCreateWithURL(url, NULL);
	if (NULL == imgSrc)
		return;

	// Copy images properties
	CFDictionaryRef imgProperties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
	if (NULL == imgProperties)
	{
		CFRelease(imgSrc);
		return;
	}

	// Get image width
	CFNumberRef pWidth = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelWidth);
	CFNumberGetValue(pWidth, kCFNumberSInt64Type, width);
	// Get image height
	CFNumberRef pHeight = CFDictionaryGetValue(imgProperties, kCGImagePropertyPixelHeight);
	CFNumberGetValue(pHeight, kCFNumberSInt64Type, height);
	CFRelease(imgProperties);

	CFRelease(imgSrc);

	// Get the filesize, because it's not always present in the image properties dictionary :/
	*fileSize = _get_file_size(url);
}

CF_RETURNS_RETAINED CGImageRef decode_webp(CFURLRef url, size_t* width, size_t* height, size_t* fileSize)
{
	*width = 0, *height = 0, *fileSize = 0;
	NSData* data = [[NSData alloc] initWithContentsOfURL:(__bridge NSURL*)url];
	if (nil == data)
		return NULL;

	// Decode image
	const void* dataPtr = [data bytes];
	const size_t size = [data length];
	WebPDecoderConfig config;
	if (!WebPInitDecoderConfig(&config))
		return NULL;

	if (WebPGetFeatures(dataPtr, size, &config.input) != VP8_STATUS_OK)
		return NULL;

	config.output.colorspace = MODE_rgbA;
	if (WebPDecode(dataPtr, size, &config) != VP8_STATUS_OK)
		return NULL;

	// Get properties
	*width = (size_t)config.input.width;
	*height = (size_t)config.input.height;
	*fileSize = _get_file_size(url);

	// Create CGImage
	CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(config.output.u.RGBA.rgba, (size_t)config.input.width, (size_t)config.input.height, 8, 4 * (size_t)config.input.width, cs, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(cs);
	WebPFreeDecBuffer(&config.output);
	CGImageRef imgRef = CGBitmapContextCreateImage(bmContext);
	CGContextRelease(bmContext);
	return imgRef;
}

CF_RETURNS_RETAINED CGImageRef decode_bpg(CFURLRef url, size_t* width, size_t* height, size_t* fileSize)
{
	*width = 0, *height = 0, *fileSize = 0;

	// Open the file, get its size and read it
	FILE* f = fopen([[(__bridge NSURL*)url path] UTF8String], "rb");
	if (NULL == f)
		return NULL;

	fseek(f, 0, SEEK_END);
	const size_t buf_len = (size_t)ftell(f);
	*fileSize = buf_len;
	fseek(f, 0, SEEK_SET);

	uint8_t* buffer = (uint8_t*)malloc(buf_len);
	const size_t nb = fread(buffer, 1, buf_len, f);
	fclose(f);
	if (nb != buf_len)
	{
		free(buffer);
		return NULL;
	}

	// Decode image
	BPGDecoderContext* img = bpg_decoder_open();
	int ret = bpg_decoder_decode(img, buffer, (int)buf_len);
	free(buffer);
	if (ret < 0)
	{
		bpg_decoder_close(img);
		return NULL;
	}

	// Get image infos
	BPGImageInfo img_info_s, *img_info = &img_info_s;
	bpg_decoder_get_info(img, img_info);
	const size_t w = (size_t)img_info->width;
	const size_t h = (size_t)img_info->height;
	*width = w;
	*height = h;

	// Always output in RGBA format
	const size_t stride = 4 * w;
	const size_t size = stride * h;
	uint8_t* final = (uint8_t*)malloc(size);
	size_t idx = 0;
	bpg_decoder_start(img, BPG_OUTPUT_FORMAT_RGBA32);
	for (size_t y = 0; y < h; y++)
	{
		bpg_decoder_get_line(img, final + idx);
		idx += stride;
	}
	bpg_decoder_close(img);

	// Create CGImage
	CGDataProviderRef dp = CGDataProviderCreateWithCFData((__bridge CFDataRef)[[NSData alloc] initWithBytesNoCopy:final length:size freeWhenDone:NO]);
	CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
	CGImageRef imgRef = CGImageCreate(w, h, 8, 32, stride, cs, kCGBitmapByteOrderDefault | kCGImageAlphaNone, dp, NULL, true, kCGRenderingIntentDefault);
	CGColorSpaceRelease(cs);
	CGDataProviderRelease(dp);
	free(final);
	return imgRef;
}

CF_RETURNS_RETAINED CGImageRef decode_portable_pixmap(CFURLRef url, size_t* width, size_t* height, size_t* fileSize)
{
	// Grab image data
	NSData* data = [[NSData alloc] initWithContentsOfURL:(__bridge NSURL*)url];
	if (nil == data)
		return NULL;
	const uint8_t* bytes = (uint8_t*)[data bytes];
	if (NULL == bytes)
		return NULL;

	// Identify type (handle binary only)
	if ((char)bytes[0] != 'P')
		return NULL;

	// Only handle binary version for now
	uint8_t* rgbBuffer = NULL;
	const char idd = (char)bytes[1];
	if (idd == '4'/* || idd == '1'*/) // pbm
		rgbBuffer = _decode_pbm(bytes, [data length], width, height);
	else if (idd == '5'/* || idd == '2'*/) // pgm
		rgbBuffer = _decode_pgm(bytes, [data length], width, height);
	else if (idd == '6'/* || idd == '3'*/) // ppm
		rgbBuffer = _decode_ppm(bytes, [data length], width, height);
	else
		return NULL;

	// Get the filesize
	*fileSize = _get_file_size(url);

	// Create CGImage
	CGDataProviderRef dp = CGDataProviderCreateWithCFData((__bridge CFDataRef)[[NSData alloc] initWithBytesNoCopy:rgbBuffer length:[data length] * 3 freeWhenDone:NO]);
	CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
	CGImageRef imgRef = CGImageCreate(*width, *height, 8, 24, 3 * *width, cs, kCGBitmapByteOrderDefault | kCGImageAlphaNone, dp, NULL, true, kCGRenderingIntentDefault);
	CGColorSpaceRelease(cs);
	CGDataProviderRelease(dp);
	free(rgbBuffer);
	return imgRef;
}

#pragma mark - Private
static void* _decode_pbm(__unused const uint8_t* bytes, __unused const size_t size, __unused size_t* width, __unused size_t* height)
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
	rgb_pixel* buf = (rgb_pixel*)malloc(((size - index + 1) * 8) * 3);
	i = 0;
	while (index < size)
	{
		uint8_t b = bytes[index++];
		for (int a = 8; a >= 1; a--)
		{
			uint8_t tmp = ((b >> a) & 0x01);
			tmp = (0 == tmp) ? 255 : 0;
			buf[i++] = (rgb_pixel){tmp, tmp, tmp};
		}
	}

	return buf;
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
	const size_t maxVal = (size_t)atol(ctmp);
	if (maxVal > 255)
		return NULL; // 16-bit, ignore.

	// Convert to RGB
	const size_t acutalSize = (size - index + 1);
	rgb_pixel* buf = (rgb_pixel*)malloc(sizeof(rgb_pixel) * acutalSize);
	const float ratio = (float)maxVal / 255.0f;
	i = 0;
	if ((int)ratio == 1)
	{
		while (index < size)
		{
			const uint8_t b = bytes[index++];
			buf[i++] = (rgb_pixel){b, b, b};
		}
	}
	else
	{
		while (index < size)
		{
			const uint8_t b = (uint8_t)((float)bytes[index++] / ratio);
			buf[i++] = (rgb_pixel){b, b, b};
		}
	}

	return buf;
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
	const size_t maxVal = (size_t)atol(ctmp);
	if (maxVal > 255)
		return NULL; // 16-bit, ignore.

	void* buf = NULL;
	const size_t acutalSize = (size - index + 1);
	const float ratio = (float)maxVal / 255.0f;
	if ((int)ratio == 1)
	{
		// Got the same ratio, just have to make a copy
		buf = (uint8_t*)malloc(sizeof(uint8_t) * acutalSize);
		memcpy(buf, &(bytes[index]), acutalSize);
	}
	else
	{
		// Moronic case, whoever does this deserve to die
		float* dataAsFloat = (float*)malloc(sizeof(float) * acutalSize);
		buf = (uint8_t*)malloc(sizeof(uint8_t) * acutalSize);
		vDSP_vfltu8(&(bytes[index]), 1, dataAsFloat, 1, acutalSize);
		vDSP_vsdiv(dataAsFloat, 1, &ratio, dataAsFloat, 1, acutalSize);
		vDSP_vfixu8(dataAsFloat, 1, buf, 1, acutalSize);
		free(dataAsFloat);
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

	return buf;
}

static size_t _get_file_size(CFURLRef url)
{
	UInt8 buf[4096] = {0x00};
	CFURLGetFileSystemRepresentation(url, true, buf, 4096);
	struct stat st;
	stat((const char*)buf, &st);
	return (size_t)st.st_size;
}
