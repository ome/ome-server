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
#define M_PLANE         10
#define M_SETPLANE      11
#define M_GETPLANE      12
#define M_GETPLANESTATS 13
#define M_GETSTACKSTATS 14

	/* STACK METHODS */
#define M_STACK         20
#define M_SETSTACK      21
#define M_GETSTACK      22

	/* ROI METHODS */
#define M_SETROI        30
#define M_GETROI        31

	/* FILE METHODS */
#define M_FILEINFO      40
#define M_FILESHA1      41 
#define M_UPLOADFILE    42
#define M_READFILE      43
#define M_DELETEFILE    44

	/* OTHER/UTILITY METHODS */
#define M_GETLOCALPATH  50
#define M_CONVERT       51
#define M_IMPORTOMEFILE 52
#define M_CONVERTSTACK  53
#define M_CONVERTPLANE  54
#define M_CONVERTTIFF   55
#define M_CONVERTROWS   56
#define M_COMPOSITE     57
#define M_GETTHUMB      58

