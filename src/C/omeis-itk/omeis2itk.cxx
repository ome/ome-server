/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2005 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */
 
 
/*------------------------------------------------------------------------------
 *
 * Written by:	Tom J. Macura <tmacura@nih.gov>   
 * 
 *------------------------------------------------------------------------------
 */
 
#include "itkImage.h"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
//#include "itkTIFFImageIO.h"
#include "itkOMEISImageIO.h"

#include <iostream>

int main(int argc, char* argv[])
{
	/* interpret command-line program parameters */
	if (argc != 2) {
		std::cerr << "USAGE: " << argv[0] << " <INPUT_FILENAME>" << std::endl;
		return EXIT_FAILURE;
	}
	char* input_filename = argv[1];
	char output_filename[16];
	sprintf(output_filename, "%s", "out.tif");
	
	typedef char           MET_CHAR;
	typedef unsigned char  MET_UCHAR;
	typedef short          MET_SHORT;
	typedef unsigned short MET_USHORT;
	typedef int            MET_INT;
	typedef unsigned int   MET_UINT;
	typedef float          MET_FLOAT;

	// typedef int PixelType;	
	typedef unsigned short int PixelType;	
	// typedef unsigned char PixelType;	

	const int Dimension = 2;
	typedef itk::Image< PixelType, Dimension> ImageType;

	typedef itk::ImageFileReader<ImageType> ReaderType;
	typedef itk::ImageFileWriter<ImageType> WriterType;
	//typedef itk::TIFFImageIO                ImageIOType;
	typedef itk::OMEISImageIO ImageIOType;

	ImageIOType::Pointer OMEIS_IO = ImageIOType::New();
	
	ReaderType::Pointer reader  = ReaderType::New();
	WriterType::Pointer writer  = WriterType::New();
	//ImageIOType::Pointer tiffIO = ImageIOType::New();
	
	reader -> SetFileName (input_filename);
	reader -> SetImageIO (OMEIS_IO);
	reader -> Update();

	
	writer -> SetInput (reader->GetOutput());
	writer -> SetImageIO (OMEIS_IO);
	writer -> SetFileName (output_filename);
	
	std::cout << "ITK Hello World !" << std::endl;
	
	try
	{
		writer->Update();
		std::cout << "DONE !" << std::endl;
	}
	catch (itk::ExceptionObject & err)
	{
		std::cerr << "ExceptionObject caught !" << std::endl;
		std::cerr <<  err << std::endl;
		return EXIT_FAILURE;
	}
	return EXIT_SUCCESS;
}