/*
 * org.openmicroscopy.ImagePixels
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy;

import java.io.IOException;

public interface ImagePixels
{
    public Attribute getDimensions();
    public byte[] getPixels()
        throws IOException;
    public byte[] getPlane(int z, int c, int t)
        throws IOException;
    public byte[] getStack(int c, int t)
        throws IOException;
    public byte[] getROI(int x0, int y0, int z0, int c0, int t0,
                         int x1, int y1, int z1, int c1, int t1)
        throws IOException;

    public int getPixelsBufferSize();
    public int getPlaneBufferSize(int z, int c, int t);
    public int getStackBufferSize(int c, int t);
    public int getROIBufferSize(int x0, int y0, int z0, int c0, int t0,
                                int x1, int y1, int z1, int c1, int t1);

    public void getPixels(byte[] buf)
        throws IOException;
    public void getPlane(byte[] buf, int z, int c, int t)
        throws IOException;
    public void getStack(byte[] buf, int c, int t)
        throws IOException;
    public void getROI(byte[] buf,
                       int x0, int y0, int z0, int c0, int t0,
                       int x1, int y1, int z1, int c1, int t1)
        throws IOException;

    public void finishPixels();
}
