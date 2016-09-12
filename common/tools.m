//
//  tools.m
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//


#import "tools.h"
#import <sys/stat.h>
#import <sys/types.h>
#import <ImageIO/ImageIO.h>


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

size_t read_file(CFStringRef filepath, uint8_t** buffer)
{
	// Open the file, get its size and read it
	FILE* f = fopen([(__bridge NSString*)filepath UTF8String], "rb");
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

const char* colorspace_string(const colorspace_t cs)
{
	switch (cs)
	{
		case colorspace_unknown:
			return "Unknown";
		case colorspace_rgb:
			return "RGB";
		case colorspace_ycbcr:
			return "Y'CbCr";
		case colorspace_ycgco:
			return "Y'CgCo";
		case colorspace_bt709:
			return "BT.709";
		case colorspace_bt2020:
			return "BT.2020";
		default:
			return "Unknown";
	}
}

#pragma mark - Private
static size_t _get_file_size(CFURLRef url)
{
	UInt8 buf[4096] = {0x00};
	CFURLGetFileSystemRepresentation(url, true, buf, 4096);
	struct stat st;
	stat((const char*)buf, &st);
	return (size_t)st.st_size;
}
