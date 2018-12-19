//
//  tools.h
//  qlImageSize
//
//  Created by @Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Nyx0uf. All rights reserved.
//


#import <Foundation/Foundation.h>

#define NYX_QL_SUPPORT_BPG_DECODE
#define NYX_MD_SUPPORT_BPG_DECODE
#define NYX_QL_SUPPORT_WEBP_DECODE
#define NYX_MD_SUPPORT_WEBP_DECODE
//#define NYX_QL_SUPPORT_NETPBM_DECODE
#define NYX_MD_SUPPORT_NETPBM_DECODE

#define SAFE_CFRelease(ptr) do { if (ptr != NULL){ CFRelease(ptr); ptr = NULL;}} while(0)


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
	size_t dpi;
} image_infos;


void properties_for_file(CFURLRef url, size_t* width, size_t* height, size_t* dpi, size_t* file_size);

size_t read_file(CFStringRef filepath, uint8_t** buffer);

const char* colorspace_string(const colorspace_t cs);
