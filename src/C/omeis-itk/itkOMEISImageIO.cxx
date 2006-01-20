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
 
#include "itkOMEISImageIO.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include <iostream> // for debugging
#include <fstream>
#include <string>

#include "itkImageIOBase.h"
extern "C" {
	#include "httpOMEIS.h";
	#include "itkOMEIS.h";
}

namespace itk
{

void OMEISImageIO::Clean(void)
{
	std::cout << "OMEISImageIO::Clean\n";
	if (this->OMEIS != NULL)
		free (this->OMEIS);

	this->OMEIS_url.clear();
	this->OMEIS_session_key.clear();
	this->OMEIS_PixelsID = 0; // sentinel value
	this->dims5D = false;
	
}

bool OMEISImageIO::CanReadFile (const char* file) 
{
	std::cout << "OMEISImageIO::CanReadFile\n";
	this->Clean();
	
	// first check the extension
	std::string filename = file;

	if (filename == "") {
		itkDebugMacro ( << "No filename specified." );
		return false;
	}
	
	// check if the file can be opened for reading
	std::ifstream OMEIS_LOCAL(filename.c_str());
	
	// check if file is a properly structured OMEIS-LOCAL. i.e. contains
	// i. magic-string
	// ii. PixelsID is properly specified
	std::string buffer;
	OMEIS_LOCAL >> buffer;
	
	if (buffer.compare(0, 12, "#OMEIS-LOCAL") != 0)
		return false;
		
	OMEIS_LOCAL >> this->OMEIS_url;
	OMEIS_LOCAL.ignore(); // ignore the new-line character
	
	std::getline (OMEIS_LOCAL, buffer, '=');
	
	if (buffer != "PixelsID") {
		std::cout << "clean up" << std::endl;
		this->Clean();
		return false;
	}
	
	OMEIS_LOCAL >> buffer;
	char* endptr;
	// endptr serves to determine where there is the first non-numerical
	// character in the string. 10 is the radix. i.e. interpret the string as decimal
	this->OMEIS_PixelsID = strtoul(buffer.c_str(), &endptr,10);
	
	OMEIS_LOCAL.close();
	return true;
}

void OMEISImageIO::ReadImageInformation ()
{
	std::cout << "OMEISImageIO::ReadImageInformation\n";
	// if the image wasn't CanReadFile'd before we need to do it now
	// this usually happens only when the user sets the ImageIO manually
	if (this->OMEIS_PixelsID == 0) {
		if (!this->CanReadFile (this->m_FileName.c_str())) {
			itkExceptionMacro ( << "Cannot open the file: " << this->m_FileName.c_str() );
			return;
		}
	}
	std::cout << "CanReadFile \n";
	
	// connect to OMEIS and get header information
	this->OMEIS = openConnectionOMEIS (this->OMEIS_url.c_str(),
									   this->OMEIS_session_key.c_str());
	std::cout << "Got openConnectionOMEIS \n";
	
	pixHeader* OMEIS_im_header;
	OMEIS_im_header = pixelsInfo (this->OMEIS, this->OMEIS_PixelsID);
	
	
	if (OMEIS_im_header == NULL) {
		itkExceptionMacro ( << "Couldn't get Pixels Info from OMEIS.\n"
						<< "Most probably either the URL (" << this->OMEIS_url
						<< ") or the PixelsID (" << this->OMEIS_PixelsID
						<< ") is wrong");
		return;
	}
	
	std::cout << "Got pixelsInfo\n";
	
	//  set m_Spacing, m_Origin, m_Dimensions
	if (this->dims5D == true) {
		std::cout << "dims5D is true\n";

		this->m_NumberOfDimensions = (unsigned int) 5;
		this->m_Dimensions.reserve (this->m_NumberOfDimensions);
		this->m_Spacing.reserve    (this->m_NumberOfDimensions);
		this->m_Origin.reserve     (this->m_NumberOfDimensions);
		
		this->m_Dimensions[0] = (unsigned int) OMEIS_im_header->dx;
		this->m_Spacing[0] = 1.0;
		this->m_Origin[0] = 0.0;
		this->m_Dimensions[1] = (unsigned int) OMEIS_im_header->dy;
		this->m_Spacing[1] = 1.0;
		this->m_Origin[1] = 0.0;
		this->m_Dimensions[2] = (unsigned int) OMEIS_im_header->dz;
		this->m_Spacing[2] = 1.0;
		this->m_Origin[2] = 0.0;
		this->m_Dimensions[3] = (unsigned int) OMEIS_im_header->dc;
		this->m_Spacing[3] = 1.0;
		this->m_Origin[3] = 0.0;
		this->m_Dimensions[4] = (unsigned int) OMEIS_im_header->dt;
		this->m_Spacing[4] = 1.0;
		this->m_Origin[4] = 0.0;
	
	} else {
		std::cout << "dims5D is false\n";

		this->m_NumberOfDimensions = (unsigned int) nDims (OMEIS_im_header);		
		this->m_Dimensions.reserve (this->m_NumberOfDimensions);
		this->m_Spacing.reserve    (this->m_NumberOfDimensions);
		this->m_Origin.reserve     (this->m_NumberOfDimensions);
		
		if (this->m_NumberOfDimensions >= 1) {
			this->m_Dimensions[0] = (unsigned int) OMEIS_im_header->dx;
			this->m_Spacing[0] = 1.0;
			this->m_Origin[0] = 0.0;
		}
		if (this->m_NumberOfDimensions >= 2) {
			this->m_Dimensions[1] = (unsigned int) OMEIS_im_header->dy;
			this->m_Spacing[1] = 1.0;
			this->m_Origin[1] = 0.0;
		} 
		if (this->m_NumberOfDimensions >= 3) {
			this->m_Dimensions[2] = (unsigned int) OMEIS_im_header->dz;
			this->m_Spacing[2] = 1.0;
			this->m_Origin[2] = 0.0;
		}
		if (this->m_NumberOfDimensions >= 4) {
			this->m_Dimensions[3] = (unsigned int) OMEIS_im_header->dc;
			this->m_Spacing[3] = 1.0;
			this->m_Origin[3] = 0.0;
		}
		if (this->m_NumberOfDimensions >= 5) {
			this->m_Dimensions[4] = (unsigned int) OMEIS_im_header->dt;
			this->m_Spacing[4] = 1.0;
			this->m_Origin[4] = 0.0;
		}
	}
	
	std::cout << "set dimensions, spacing, and origin\n";

	// set number of components and pixel type
	this->SetNumberOfComponents(1);
	this->SetPixelType(SCALAR);

	char* PixelType_str = OMEIStoMETDatatype (OMEIS_im_header);
	std::string PixelType (PixelType_str);
	free (PixelType_str);
	
	
	std::cout << "PixelType is " << PixelType << std::endl;

	if (PixelType == "MET_CHAR")
		this->m_ComponentType = CHAR;
	else if (PixelType == "MET_UCHAR")
		this->m_ComponentType = UCHAR;	
	else if (PixelType == "MET_SHORT")
		this->m_ComponentType = SHORT;
	else if (PixelType == "MET_USHORT")
		this->m_ComponentType = USHORT;
	else if (PixelType == "MET_INT")
		this->m_ComponentType = INT;
	else if (PixelType == "MET_UINT")
		this->m_ComponentType = UINT;
	else if (PixelType == "MET_FLOAT")
		this->m_ComponentType = FLOAT;
	else {
		itkDebugMacro ( << "Unkown PixelType " << PixelType);
		return;
	}
	
	std::cout << "All set\n";

	return;
}

void OMEISImageIO::Read (void* buffer)
{
	std::cout << "OMEISImageIO::READ \n";
	buffer = getPixels (this->OMEIS, this->OMEIS_PixelsID);
	std::cout << "... done \n";
}

bool OMEISImageIO::CanWriteFile (const char* file)
{
	std::cout << "OMEISImageIO::CanWriteFile\n";
}

void OMEISImageIO::WriteImageInformation ()
{
	std::cout << "OMEISImageIO::WriteImageInformation\n";

}

void OMEISImageIO::Write (const void* buffer)
{
	std::cout << "OMEISImageIO::Write \n";

}

OMEISImageIO::OMEISImageIO()
{
	std::cout << "OMEISImageIO::OMESImageIO\n";
	this->Clean();
}

OMEISImageIO::~OMEISImageIO()
{
	std::cout << "OMEISImageIO::~OMEISImageIO\n";
	this->Clean(); // to free this->OMEIS
}


} // end namespace itk