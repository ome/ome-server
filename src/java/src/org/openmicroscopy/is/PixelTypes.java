/*
 * org.openmicroscopy.is.PixelTypes
 *
 *------------------------------------------------------------------------------
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.is;

/**
 * Contains constants defining the string name of each possible pixel
 * type supported by the image server.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <i>(Internal: $Revision$ $Date$)</i>
 * @since OME2.2
 */

public class PixelTypes
{
    // BBP (0 = 1byte, 1=2bytes, 2=4bytes),
    // Float? (0=false, 1=true),
    // Signed? (0=false, 1=true)
    private static final String[][][] PIXEL_TYPES = 
    { { { "uint8", "int8" },
        { "invalid", "invalid" } },

      { { "uint16", "int16" },
        { "invalid", "invalid" } },

      { { "uint32", "int32" },
        { "invalid", "float" } } };

    public static String getPixelType(int bytesPerPixel,
                                      boolean isSigned,
                                      boolean isFloat)
    {
        int bbpIndex = 0;

        if (bytesPerPixel == 1)
            bbpIndex = 0;
        else if (bytesPerPixel == 2)
            bbpIndex = 1;
        else if (bytesPerPixel == 4)
            bbpIndex = 2;
        else
            return "invalid";

        return PIXEL_TYPES[bbpIndex][isFloat? 1: 0][isSigned? 1: 0];
    }

}
