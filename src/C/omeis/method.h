/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
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
 * Written by:	Chris Allan <callan@blackcat.ca>   01/2004
 * 
 *------------------------------------------------------------------------------
 */

/* METHOD RETRIEVAL FUNCTIONS */

unsigned int
get_method_by_name(char * m_name);

/* SUPPORTED CGI METHODS */

	/* PIXELS METHODS */
#define M_PIXELS        1
#define M_NEWPIXELS     2
#define M_PIXELSINFO    3
#define M_PIXELSSHA1    4
#define M_SETPIXELS     5
#define M_GETPIXELS     6
#define M_FINISHPIXELS  7

	/* PLANE METHODS */
#define M_PLANE         8
#define M_SETPLANE      9
#define M_GETPLANE      10
#define M_GETPLANESTATS 11

	/* STACK METHODS */
#define M_STACK         12
#define M_SETSTACK      13
#define M_GETSTACK      14

	/* ROI METHODS */
#define M_SETROI        15
#define M_GETROI        16

	/* FILE METHODS */
#define M_FILEINFO      17
#define M_FILESHA1      18 
#define M_UPLOADFILE    19
#define M_READFILE      20

	/* OTHER/UTILITY METHODS */
#define M_GETLOCALPATH  21
#define M_CONVERT       22
#define M_IMPORTOMEFILE 23

