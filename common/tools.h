//
//  tools.h
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//  www.cocoaintheshell.com
//


#import <Foundation/Foundation.h>


typedef enum _nyx_colorspace_t {
	colorspace_unknown = 0,
	colorspace_rgb = 1,
	colorspace_ycbcr,
	colorspace_ycgco,
	colorspace_bt709,
	colorspace_bt2020,
} colorspace_t;


typedef struct _nyx_image_infos_struct {
	size_t width;
	size_t height;
	uint8_t has_alpha;
	uint8_t bit_depth;
	size_t filesize;
	colorspace_t colorspace;
} image_infos;


void properties_for_file(CFURLRef url, size_t* width, size_t* height, size_t* file_size);

size_t read_file(CFStringRef filepath, uint8_t** buffer);

const char* colorspace_string(const colorspace_t cs);
