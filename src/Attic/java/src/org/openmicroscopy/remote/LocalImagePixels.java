/*
 * org.openmicroscopy.remote.LocalImagePixels
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

package org.openmicroscopy.remote;

import org.openmicroscopy.*;

import java.io.*;
import java.util.*;

public class LocalImagePixels
    implements ImagePixels
{
    private static Map  repositoryPaths = new HashMap();

    public static void addRepositoryPath(Attribute repository, File path)
    {
        addRepositoryPath(repository.getID(),path);
    }

    public static void addRepositoryPath(int id, File path)
    {
        repositoryPaths.put(new Integer(id),path);
    }

    public static boolean isRepositoryLocal(Attribute repository)
    {
        return isRepositoryLocal(repository.getID());
    }

    public static boolean isRepositoryLocal(int id)
    {
        return repositoryPaths.containsKey(new Integer(id));
    }

    public static File getRepositoryPath(Attribute repository)
    {
        return getRepositoryPath(repository.getID());
    }

    public static File getRepositoryPath(int id)
    {
        return (File) repositoryPaths.get(new Integer(id));
    }

    private String    relativePath;
    private Attribute pixels, repository;
    private int       sizeX, sizeY, sizeZ, sizeC, sizeT;

    public LocalImagePixels()
    {
    }

    public LocalImagePixels(Attribute pixels)
    {
        this.repository = pixels.getAttributeElement("Repository");
        this.relativePath = pixels.getStringElement("Path");
        this.pixels = pixels;
        this.sizeX = pixels.getIntElement("SizeX");
        this.sizeY = pixels.getIntElement("SizeY");
        this.sizeZ = pixels.getIntElement("SizeZ");
        this.sizeC = pixels.getIntElement("SizeC");
        this.sizeT = pixels.getIntElement("SizeT");
    }

    public Attribute getPixelsAttribute() { return pixels; }
    public void setPixelsAttribute(Attribute pixels)
    { this.pixels = pixels; }

    private RandomAccessFile  file;

    private void openFile()
        throws FileNotFoundException
    {
        File basePath = getRepositoryPath(repository);
        File fullPath = new File(basePath,relativePath);
        file = new RandomAccessFile(fullPath,"r");
    }

    private static final int BYTES_PER_PIXEL = 2;

    public int getPixelsBufferSize()
    {
        return
            sizeX*
            sizeY*
            sizeZ*
            sizeC*
            sizeT*
            BYTES_PER_PIXEL;
    }

    public int getPlaneBufferSize(int z, int c, int t)
    {
        return
            sizeX*
            sizeY*
            BYTES_PER_PIXEL;
    }

    public int getStackBufferSize(int c, int t)
    {
        return
            sizeX*
            sizeY*
            sizeZ*
            BYTES_PER_PIXEL;
    }

    public int getROIBufferSize(int x0, int y0, int z0, int c0, int t0,
                                int x1, int y1, int z1, int c1, int t1)
    {
        return
            (x1-x0)*
            (y1-y0)*
            (z1-z0)*
            (c1-c0)*
            (t1-t0)*
            BYTES_PER_PIXEL;
    }

    public byte[] getPixels()
        throws IOException
    {
        int size = getPixelsBufferSize();
        byte[] buf = new byte[size];
        getPixels(buf);
        return buf;
    }

    public byte[] getPlane(int z, int c, int t)
        throws IOException
    {
        int size = getPlaneBufferSize(z,c,t);
        byte[] buf = new byte[size];
        getPlane(buf,z,c,t);
        return buf;
    }

    public byte[] getStack(int c, int t)
        throws IOException
    {
        int size = getStackBufferSize(c,t);
        byte[] buf = new byte[size];
        getStack(buf,c,t);
        return buf;
    }

    public byte[] getROI(int x0, int y0, int z0, int c0, int t0,
                         int x1, int y1, int z1, int c1, int t1)
        throws IOException
    {
        int size = getROIBufferSize(x0,y0,z0,c0,t0,x1,y1,z1,c1,t1);
        byte[] buf = new byte[size];
        getROI(buf,x0,y0,z0,c0,t0,x1,y1,z1,c1,t1);
        return buf;
    }

    public void getPixels(byte[] buf)
        throws IOException
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        int size = getPixelsBufferSize();
        if (buf.length < size)
            throw new IllegalArgumentException("Input buffer too small");

        if (file == null) openFile();
        file.seek(0L);
        file.readFully(buf,0,size);
    }

    public void getPlane(byte[] buf, int z, int c, int t)
        throws IOException
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        int size = getPlaneBufferSize(z,c,t);
        if (buf.length < size)
            throw new IllegalArgumentException("Input buffer too small");
        if ((z < 0) || (z >= sizeZ) ||
            (c < 0) || (c >= sizeC) ||
            (t < 0) || (t >= sizeT))
            throw new IllegalArgumentException("Plane selection out of range");

        if (file == null) openFile();
        long pos = (((t*sizeC)+c)*sizeZ+z)*sizeY*sizeX*BYTES_PER_PIXEL;
        file.seek(pos);
        file.readFully(buf,0,size);
    }

    public void getStack(byte[] buf, int c, int t)
        throws IOException
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        int size = getStackBufferSize(c,t);
        if (buf.length < size)
            throw new IllegalArgumentException("Input buffer too small");
        if ((c < 0) || (c >= sizeC) ||
            (t < 0) || (t >= sizeT))
            throw new IllegalArgumentException("Stack selection out of range");

        if (file == null) openFile();
        long pos = ((t*sizeC)+c)*sizeZ*sizeY*sizeX*BYTES_PER_PIXEL;
        file.seek(pos);
        file.readFully(buf,0,size);
    }

    public void getROI(byte[] buf,
                       int x0, int y0, int z0, int c0, int t0,
                       int x1, int y1, int z1, int c1, int t1)
        throws IOException
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        int size = getROIBufferSize(x0,y0,z0,c0,t0,x1,y1,z1,c1,t1);
        if (buf.length < size)
            throw new IllegalArgumentException("Input buffer too small");
        if ((x0 > x1) || (x0 < 0) || (x1 > sizeX) ||
            (y0 > y1) || (y0 < 0) || (y1 > sizeY) ||
            (z0 > z1) || (z0 < 0) || (z1 > sizeZ) ||
            (c0 > c1) || (c0 < 0) || (c1 > sizeC) ||
            (t0 > t1) || (t0 < 0) || (t1 > sizeT))
            throw new IllegalArgumentException("ROI misconfigured");

        if (file == null) openFile();

        int offset = 0;
        int deltaX = x1-x0;
        int x = 0;

	for (int t = t0; t < t1; t++)
        {
            for (int c = c0; c < c1; c++)
            {
                for (int z = z0; z < z1; z++)
                {
                    for (int y = y0; y < y1; y++)
                    {
                        long pos = (((((t*sizeC)+c)*sizeZ+z)*sizeY+y)*sizeX+x)*BYTES_PER_PIXEL;
                        file.seek(pos);
                        file.readFully(buf,offset,deltaX*BYTES_PER_PIXEL);
                        offset += deltaX*BYTES_PER_PIXEL;
                    }
                }
            }
	}

    }

    public void finishPixels()
    {
        if (file != null)
        {
            try
            {
                file.close();
            } catch (IOException e) {
            }
            file = null;
        }
    }
}
