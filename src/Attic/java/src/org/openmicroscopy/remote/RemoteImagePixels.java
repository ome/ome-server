/*
 * org.openmicroscopy.remote.RemoteImagePixels
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

public class RemoteImagePixels
    extends RemoteObject
    implements ImagePixels
{
    public RemoteImagePixels() { super(); }
    public RemoteImagePixels(String reference) { super(reference); }

    private Attribute dimensions;

    public Attribute getDimensions() { return dimensions; }
    public void setDimensions(Attribute dimensions) { this.dimensions = dimensions; }

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

}
