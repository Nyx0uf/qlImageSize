//
//  NYXPNGTools.h
//  NYXPNGTools
//
//  Created by Nyx0uf on 02/02/12.
//  Copyright (c) 2012 Benjamin Godard. All rights reserved.
//  www.cocoaintheshell.com
//


#ifndef __NYXPNGTOOLS_H_
#define __NYXPNGTOOLS_H_


/*!
 *	@function npt_is_png
 *	@abstract Check if the file is a PNG
 *	@param path [in] : Path to file
 *	@param error [out] : Error code, use npt_error_message() for a description
 *	@return 1 = Valid PNG file, 0 = Error or not PNG
 */
extern int npt_is_png(const char* path, int* error);

/*!
 *	@function npt_is_apple_crushed_png
 *	@abstract Check if the given PNG file is Apple's crushed
 *	@param path [in] : Path to the PNG file
 *	@param error [out] : Error code, use npt_error_message() for a description
 *	@return 1 = Apple's crushed, 0 = error or not Apple's PNG
 */
extern int npt_is_apple_crushed_png(const char* path, int* error);

/*!
 *	@function npt_create_uncrushed_from_file
 *	@abstract Attempt to uncrush an Apple's iOS PNG file
 *	@param path [in] : Path to the crushed PNG file
 *	@param size [out] : Size of the returned buffer, 0 in case of error
 *	@param error [out] : Error code, use npt_error_message() for a description
 *	@return Buffer containing the uncrushed PNG data
 *	@discussion If return value is != NULL, the caller MUST free the data
 */
extern unsigned char* npt_create_uncrushed_from_file(const char* path, unsigned int* size, int* error);

/*!
 *	@function npt_error_message
 *	@abstract Returns the error string correponsing to the error code
 *	@param error [in] : Error code
 *	@return Corresponding error message
 */
extern char* npt_error_message(const int error);

#endif /* __NYXPNGTOOLS_H_ */
