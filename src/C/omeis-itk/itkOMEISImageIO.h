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

#ifndef __itkOMEISImageIO_h
#define __itkOMEISImageIO_h

#include "itkImageIOBase.h"

extern "C" {
	#include "httpOMEIS.h";
}

namespace itk
{

class ITK_EXPORT OMEISImageIO : public ImageIOBase
{
public:
	/* standard class typedefs */
	typedef OMEISImageIO       Self;
	typedef ImageIOBase        Superclass;
	typedef SmartPointer<Self> Pointer;

	/* method for creation through the object factory */
	itkNewMacro (Self);
	
	/** Run-time type information (and related materials) */
	itkTypeMacro (OMEISImageIO, Superclass);
	
	virtual bool SupportsDimension(unsigned long dims)
	{
		if (dims <= 1 || dims > 6)
			return false;
  		else
  			return true;
  	}
  
	/*****************************************************************/
	/* ---- This part of the interface deals with READING data. ---- */
	/*****************************************************************/
	
	/* Determine the file type. Returns true if the this ImageIO can read the
	   file specified */
	virtual bool CanReadFile (const char*);
	
	/* Get the dimension information for the set filename */
	virtual void ReadImageInformation ();
	
	/* reads data from remote OMEIS into the memory buffer provided. */
	virtual void Read (void* buffer);
	
	/*****************************************************************/
	/* ---- This part of the interface deals with WRITING data. ---- */
	/*****************************************************************/

	/* Determine the file type. Returns true if the this ImageIO can write the
	   file specified */
	virtual bool CanWriteFile (const char*);
	
	/* Writes the dimension information for the image */
	virtual void WriteImageInformation ();
	
	/* Writes the data to disk from the memory buffer provided. */
	virtual void Write (const void* buffer);
	
	/* set connection to OMEIS */
	void SetOMEISUrl        (std::string url)         { OMEIS_url = url; }
	void SetOMEISSessionKey (std::string session_key) { OMEIS_session_key = session_key; }
	
	/* many images stored in OMEIS < 5-D have the extents of the higher
	dimensions set to 1. so these images aren't really 5D but are stored that way
	itk can handle such images according to their lower more realistic dimensions
	or as 5D images */
	void SetDims5D (bool yes)
	{
		if (yes == true)
			dims5D = true;
		else
			dims5D = false;
	}

protected:
	OMEISImageIO ();
	~OMEISImageIO ();
	
private:
	void Clean(); // makes the private data nice and fresh
	
	/* connection to the proper OMEIS */
	std::string OMEIS_url;
	std::string OMEIS_session_key;
	OID OMEIS_PixelsID;

	omeis* OMEIS;
	bool dims5D;
	
	OMEISImageIO   (const Self&); // purposely not implemented
	void operator= (const Self&); // purposely not implemented
};

} // end namespace itk

#endif // __itkOMEISImageIO.h