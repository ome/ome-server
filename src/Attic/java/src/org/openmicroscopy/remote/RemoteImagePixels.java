/*
 * org.openmicroscopy.remote.RemoteImagePixels
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




package org.openmicroscopy.remote;

import org.openmicroscopy.*;

public class RemoteImagePixels
    extends RemoteObject
    implements ImagePixels
{
    static
    {
        RemoteObjectCache.addClass("OME::Image::Pixels",RemoteImagePixels.class);
    }

    public RemoteImagePixels() { super(); }
    public RemoteImagePixels(RemoteSession session, String reference)
    { super(session,reference); }

    private Attribute pixels;

    public Attribute getPixelsAttribute() { return pixels; }
    public void setPixelsAttribute(Attribute pixels) { this.pixels = pixels; }

    public byte[] getPixels()
    {
        Object o = caller.dispatch(this,"GetPixels");
        if (o instanceof byte[])
            return (byte[]) o;
        else if (o == null)
            return null;
        else
            throw new RemoteException("GetPixels: expect byte[], got "+o.getClass());
    }

    public byte[] getPlane(int z, int c, int t)
    {
        Object o = caller.dispatch(this,"GetPlane",
                                   new Object[] {
                                       new Integer(z),
                                       new Integer(c),
                                       new Integer(t)
                                   });
        if (o instanceof byte[])
            return (byte[]) o;
        else if (o == null)
            return null;
        else
            throw new RemoteException("GetPlane: expect byte[], got "+o.getClass());
    }

    public byte[] getStack(int c, int t)
    {
        Object o = caller.dispatch(this,"GetStack",
                                   new Object[] {
                                       new Integer(c),
                                       new Integer(t)
                                   });
        if (o instanceof byte[])
            return (byte[]) o;
        else if (o == null)
            return null;
        else
            throw new RemoteException("GetStack: expect byte[], got "+o.getClass());
    }

    public byte[] getROI(int x0, int y0, int z0, int c0, int t0,
                         int x1, int y1, int z1, int c1, int t1)
    {
        Object o = caller.dispatch(this,"GetROI",
                                   new Object[] {
                                       new Integer(x0),
                                       new Integer(y0),
                                       new Integer(z0),
                                       new Integer(c0),
                                       new Integer(t0),
                                       new Integer(x1),
                                       new Integer(y1),
                                       new Integer(z1),
                                       new Integer(c1),
                                       new Integer(t1)
                                   });
        if (o instanceof byte[])
            return (byte[]) o;
        else if (o == null)
            return null;
        else
            throw new RemoteException("GetROI: expect byte[], got "+o.getClass());
    }

    public int getPixelsBufferSize()
    {
        return
            pixels.getIntElement("SizeX")*
            pixels.getIntElement("SizeY")*
            pixels.getIntElement("SizeZ")*
            pixels.getIntElement("SizeC")*
            pixels.getIntElement("SizeT")*
            (pixels.getIntElement("BitsPerPixel")/8);
    }

    public int getPlaneBufferSize(int z, int c, int t)
    {
        return
            pixels.getIntElement("SizeX")*
            pixels.getIntElement("SizeY")*
            (pixels.getIntElement("BitsPerPixel")/8);
    }

    public int getStackBufferSize(int c, int t)
    {
        return
            pixels.getIntElement("SizeX")*
            pixels.getIntElement("SizeY")*
            pixels.getIntElement("SizeZ")*
            (pixels.getIntElement("BitsPerPixel")/8);
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
            (pixels.getIntElement("BitsPerPixel")/8);
    }

    public void getPixels(byte[] buf)
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        byte[] inBuf = getPixels();
        if (buf.length < inBuf.length)
            throw new IllegalArgumentException("Input buffer too small");
        for (int i = 0; i < inBuf.length; i++)
            buf[i] = inBuf[i];
    }

    public void getPlane(byte[] buf, int z, int c, int t)
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        byte[] inBuf = getPlane(z,c,t);
        if (buf.length < inBuf.length)
            throw new IllegalArgumentException("Input buffer too small");
        for (int i = 0; i < inBuf.length; i++)
            buf[i] = inBuf[i];
    }

    public void getStack(byte[] buf, int c, int t)
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        byte[] inBuf = getStack(c,t);
        if (buf.length < inBuf.length)
            throw new IllegalArgumentException("Input buffer too small");
        for (int i = 0; i < inBuf.length; i++)
            buf[i] = inBuf[i];
    }

    public void getROI(byte[] buf,
                       int x0, int y0, int z0, int c0, int t0,
                       int x1, int y1, int z1, int c1, int t1)
    {
        if (buf == null) 
            throw new IllegalArgumentException("Input buffer is null");
        byte[] inBuf = getROI(x0,y0,z0,c0,t0,x1,y1,z1,c1,t1);
        if (buf.length < inBuf.length)
            throw new IllegalArgumentException("Input buffer too small");
        for (int i = 0; i < inBuf.length; i++)
            buf[i] = inBuf[i];
    }

    public void finishPixels() {}
}
