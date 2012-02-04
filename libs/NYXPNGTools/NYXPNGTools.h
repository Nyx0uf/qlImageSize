//
//  NYXPNGTools.h
//  NYXPNGTools
//
//  Created by Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Benjamin Godard. All rights reserved.
//  www.cocoabyss.com
//


#ifndef __NYXPNGTOOLS_H_
#define __NYXPNGTOOLS_H_


/*!
 *	@function npt_is_apple_crushed_png
 *	@abstract Check if the given PNG file is Apple's crushed
 *	@param path [in] : Path to the PNG file
 *	@return 1 = Apple's crushed
 */
extern int npt_is_apple_crushed_png(const char* path);

/*!
 *	@function npt_create_uncrushed_from_file
 *	@abstract Attempt to uncrush an Apple's iOS PNG file
 *	@param path [in] : Path to the crushed PNG file
 *	@param size [out] : Size of the returned buffer, 0 in case of error
 *	@return Buffer containing the uncrushed PNG data
 *	@discussion If return value is != NULL, the caller MUST free the data
 */
extern unsigned char* npt_create_uncrushed_from_file(const char* path, unsigned int* size);

#endif /* __NYXPNGTOOLS_H_ */
